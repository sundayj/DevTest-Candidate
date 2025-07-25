# Task 7: Database Query Optimization

**Time Allocation**: 2-3 hours  
**Difficulty Level**: Mid to Senior Level  
**Focus Areas**: Database Performance, Query Optimization, Django ORM

## Overview

Optimize database queries in the DevTest book catalog system to improve performance and scalability. This task evaluates your understanding of database optimization principles, Django ORM efficiency, and ability to identify and resolve performance bottlenecks.

## Project Setup

Follow the [Running the Project guide](../setup/running-project.md) to start the application with DevContainer, Docker Compose, or GitHub Codespaces.

## Task Requirements

### Core Optimization Tasks (Required)

1. **Optimize AuthorQuerySet Methods**
   - Improve the existing `with_average_rating()` method
   - Enhance the `top_authors()` method performance
   - Add database indexes for better query performance
   - Handle edge cases efficiently

2. **Eliminate N+1 Query Problems**
   - Identify and fix N+1 queries in book listings
   - Optimize author and genre relationships
   - Improve review loading performance
   - Use appropriate select_related and prefetch_related

3. **Complex Query Optimization**
   - Create efficient queries for book statistics
   - Optimize genre-based filtering
   - Improve search functionality performance
   - Handle large dataset scenarios

4. **Database Schema Optimization**
   - Add appropriate database indexes
   - Optimize foreign key relationships
   - Consider denormalization where beneficial
   - Implement database constraints

### Advanced Optimization Features (Optional)

- Query result caching
- Database connection pooling
- Raw SQL optimization for complex queries
- Database partitioning strategies
- Query performance monitoring

## Implementation Guidelines

### 1. Analyzing Current Performance

#### Enable Query Logging
```python
# settings.py - Add for development
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django.db.backends': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
    },
}
```

#### Query Analysis Tools
```python
# utils/query_analyzer.py
from django.db import connection
from django.conf import settings
import time

class QueryAnalyzer:
    def __init__(self):
        self.start_queries = len(connection.queries)
        self.start_time = time.time()
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        end_time = time.time()
        end_queries = len(connection.queries)
        
        query_count = end_queries - self.start_queries
        execution_time = end_time - self.start_time
        
        print(f"Queries executed: {query_count}")
        print(f"Execution time: {execution_time:.4f} seconds")
        
        if settings.DEBUG and query_count > 0:
            print("\nQuery details:")
            for query in connection.queries[self.start_queries:]:
                print(f"Time: {query['time']}s")
                print(f"SQL: {query['sql'][:100]}...")
                print("-" * 50)

# Usage example
def test_book_list_performance():
    with QueryAnalyzer():
        books = Book.objects.all()
        for book in books:
            print(f"{book.title} by {book.author.name}")
```

### 2. Optimizing AuthorQuerySet Methods

#### Current Implementation Analysis
```python
# Current models.py - Analyze this
class AuthorQuerySet(models.QuerySet):
    def with_average_rating(self):
        """Annotate authors with their average review rating and counts."""
        return self.annotate(
            avg_rating=Avg("book__review__rating"),
            book_count=Count("book", distinct=True),
            review_count=Count("book__review", distinct=True),
        )

    def top_authors(self, limit=5):
        """Return the top authors ordered by average rating."""
        return (
            self.with_average_rating()
            .order_by(models.F("avg_rating").desc(nulls_last=True))[:limit]
        )
```

#### Optimized Implementation
```python
# Optimized models.py
from django.db import models
from django.db.models import Avg, Count, Q, F, Case, When, Value
from django.db.models.functions import Coalesce

class AuthorQuerySet(models.QuerySet):
    def with_average_rating(self):
        """Optimized version with better performance."""
        return self.annotate(
            # Use Coalesce to handle null values efficiently
            avg_rating=Coalesce(
                Avg("book__review__rating", 
                    filter=Q(book__review__rating__isnull=False)), 
                Value(0.0)
            ),
            book_count=Count("book", distinct=True),
            review_count=Count("book__review", distinct=True),
            # Add helpful computed fields
            has_books=Case(
                When(book_count__gt=0, then=Value(True)),
                default=Value(False),
                output_field=models.BooleanField()
            )
        )
    
    def top_authors(self, limit=5, min_reviews=1):
        """Enhanced top authors with minimum review threshold."""
        return (
            self.with_average_rating()
            .filter(
                book_count__gt=0,  # Only authors with books
                review_count__gte=min_reviews  # Minimum review threshold
            )
            .order_by(
                F("avg_rating").desc(nulls_last=True),
                F("review_count").desc()  # Secondary sort by review count
            )[:limit]
        )
    
    def by_genre(self, genre):
        """Get authors who have written books in a specific genre."""
        return self.filter(book__genres=genre).distinct()
    
    def with_recent_activity(self, days=30):
        """Authors with recent review activity."""
        from django.utils import timezone
        from datetime import timedelta
        
        cutoff_date = timezone.now() - timedelta(days=days)
        return self.filter(
            book__review__created_at__gte=cutoff_date
        ).distinct()

class Author(models.Model):
    name = models.CharField(max_length=100, db_index=True)  # Add index
    
    objects = AuthorQuerySet.as_manager()
    
    class Meta:
        indexes = [
            models.Index(fields=['name']),
            # Add composite indexes for common queries
        ]
    
    def __str__(self) -> str:
        return self.name
```

### 3. Eliminating N+1 Queries

#### Problem Identification
```python
# views.py - PROBLEMATIC CODE
def book_list(request):
    books = Book.objects.all()  # 1 query
    context = {'books': books}
    return render(request, 'app/book_list.html', context)

# In template: book_list.html
# {% for book in books %}
#   {{ book.title }} by {{ book.author.name }}  # N queries for authors
#   Genres: {% for genre in book.genres.all %}{{ genre.name }}{% endfor %}  # N queries for genres
# {% endfor %}
```

#### Optimized Solution
```python
# views.py - OPTIMIZED CODE
def book_list(request):
    """Optimized book list with proper prefetching."""
    books = Book.objects.select_related(
        'author'  # Join author table
    ).prefetch_related(
        'genres',  # Prefetch genres in separate query
        'review_set'  # Prefetch reviews if needed
    ).annotate(
        avg_rating=Avg('review__rating'),
        review_count=Count('review')
    ).order_by('title')
    
    context = {'books': books}
    return render(request, 'app/book_list.html', context)

def book_detail(request, pk):
    """Optimized book detail view."""
    book = get_object_or_404(
        Book.objects.select_related('author')
        .prefetch_related(
            'genres',
            Prefetch(
                'review_set',
                queryset=Review.objects.select_related('user')
                .order_by('-created_at')
            )
        ),
        pk=pk
    )
    
    context = {'book': book}
    return render(request, 'app/book_detail.html', context)

def author_detail(request, pk):
    """Optimized author detail with books and stats."""
    author = get_object_or_404(
        Author.objects.prefetch_related(
            Prefetch(
                'book_set',
                queryset=Book.objects.prefetch_related('genres')
                .annotate(
                    avg_rating=Avg('review__rating'),
                    review_count=Count('review')
                )
            )
        ),
        pk=pk
    )
    
    context = {'author': author}
    return render(request, 'app/author_detail.html', context)
```

### 4. Complex Query Optimization

#### Book Statistics Queries
```python
# queries.py - Complex optimized queries
from django.db.models import Q, F, Count, Avg, Max, Min
from django.db.models.functions import TruncMonth, TruncYear

class BookQueryOptimizer:
    """Collection of optimized book queries."""
    
    @staticmethod
    def books_with_stats():
        """Get books with comprehensive statistics."""
        return Book.objects.select_related('author').prefetch_related('genres').annotate(
            avg_rating=Coalesce(Avg('review__rating'), Value(0.0)),
            review_count=Count('review'),
            latest_review=Max('review__created_at'),
            rating_distribution=Count(
                Case(
                    When(review__rating=5, then=1),
                    output_field=models.IntegerField()
                )
            )
        )
    
    @staticmethod
    def top_books_by_genre(genre_id, limit=10):
        """Get top books in a specific genre."""
        return Book.objects.filter(
            genres__id=genre_id
        ).select_related('author').annotate(
            avg_rating=Avg('review__rating'),
            review_count=Count('review')
        ).filter(
            review_count__gte=5  # Minimum reviews for reliability
        ).order_by('-avg_rating', '-review_count')[:limit]
    
    @staticmethod
    def books_by_rating_range(min_rating=4.0, max_rating=5.0):
        """Get books within a rating range."""
        return Book.objects.annotate(
            avg_rating=Avg('review__rating')
        ).filter(
            avg_rating__gte=min_rating,
            avg_rating__lte=max_rating
        ).select_related('author').prefetch_related('genres')
    
    @staticmethod
    def monthly_book_stats(year=None):
        """Get monthly statistics for books."""
        queryset = Review.objects.select_related('book')
        
        if year:
            queryset = queryset.filter(created_at__year=year)
        
        return queryset.annotate(
            month=TruncMonth('created_at')
        ).values('month').annotate(
            review_count=Count('id'),
            avg_rating=Avg('rating'),
            unique_books=Count('book', distinct=True)
        ).order_by('month')

class AuthorQueryOptimizer:
    """Collection of optimized author queries."""
    
    @staticmethod
    def prolific_authors(min_books=3):
        """Get authors with multiple books."""
        return Author.objects.annotate(
            book_count=Count('book')
        ).filter(
            book_count__gte=min_books
        ).annotate(
            avg_rating=Avg('book__review__rating'),
            total_reviews=Count('book__review')
        ).order_by('-book_count', '-avg_rating')
    
    @staticmethod
    def authors_by_genre_expertise(genre_id):
        """Get authors who specialize in a genre."""
        return Author.objects.filter(
            book__genres__id=genre_id
        ).annotate(
            books_in_genre=Count('book', filter=Q(book__genres__id=genre_id)),
            total_books=Count('book'),
            genre_percentage=F('books_in_genre') * 100.0 / F('total_books')
        ).filter(
            books_in_genre__gte=2  # At least 2 books in genre
        ).order_by('-genre_percentage', '-books_in_genre')
```

### 5. Database Schema Optimization

#### Index Optimization
```python
# models.py - Enhanced with indexes
class Book(models.Model):
    title = models.CharField(max_length=200, db_index=True)
    author = models.ForeignKey(Author, on_delete=models.CASCADE, db_index=True)
    genres = models.ManyToManyField(Genre, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['title']),
            models.Index(fields=['author', 'title']),
            models.Index(fields=['-created_at']),
            # Composite index for common queries
            models.Index(fields=['author', '-created_at']),
        ]

class Review(models.Model):
    book = models.ForeignKey(Book, on_delete=models.CASCADE, db_index=True)
    user = models.ForeignKey('auth.User', on_delete=models.CASCADE, db_index=True)
    rating = models.PositiveSmallIntegerField(db_index=True)
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['book', '-created_at']),
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['rating', '-created_at']),
            # Composite index for book statistics
            models.Index(fields=['book', 'rating']),
        ]
        # Prevent duplicate reviews
        unique_together = ['book', 'user']

class Genre(models.Model):
    name = models.CharField(max_length=50, unique=True, db_index=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['name']),
        ]
```

#### Migration for Indexes
```python
# migrations/XXXX_add_performance_indexes.py
from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [
        ('app', '0001_initial'),
    ]

    operations = [
        migrations.RunSQL(
            "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_book_title_trgm ON app_book USING gin (title gin_trgm_ops);",
            reverse_sql="DROP INDEX IF EXISTS idx_book_title_trgm;"
        ),
        migrations.RunSQL(
            "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_author_name_trgm ON app_author USING gin (name gin_trgm_ops);",
            reverse_sql="DROP INDEX IF EXISTS idx_author_name_trgm;"
        ),
    ]
```

### 6. Query Caching Implementation

#### Cache Configuration
```python
# settings.py
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://redis:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    }
}

# Cache timeout settings
CACHE_TIMEOUT = {
    'BOOK_LIST': 300,  # 5 minutes
    'AUTHOR_STATS': 1800,  # 30 minutes
    'TOP_AUTHORS': 3600,  # 1 hour
}
```

#### Cached Query Implementation
```python
# utils/cached_queries.py
from django.core.cache import cache
from django.conf import settings
import hashlib

class CachedQueries:
    """Cached query implementations."""
    
    @staticmethod
    def get_cache_key(prefix, *args, **kwargs):
        """Generate cache key from arguments."""
        key_data = f"{prefix}:{args}:{sorted(kwargs.items())}"
        return hashlib.md5(key_data.encode()).hexdigest()
    
    @classmethod
    def get_top_authors(cls, limit=5, min_reviews=1):
        """Cached top authors query."""
        cache_key = cls.get_cache_key('top_authors', limit, min_reviews=min_reviews)
        
        result = cache.get(cache_key)
        if result is None:
            result = list(
                Author.objects.top_authors(limit=limit, min_reviews=min_reviews)
                .values('id', 'name', 'avg_rating', 'book_count', 'review_count')
            )
            cache.set(cache_key, result, settings.CACHE_TIMEOUT['TOP_AUTHORS'])
        
        return result
    
    @classmethod
    def get_book_stats(cls, book_id):
        """Cached book statistics."""
        cache_key = cls.get_cache_key('book_stats', book_id)
        
        result = cache.get(cache_key)
        if result is None:
            book = Book.objects.select_related('author').prefetch_related('genres').annotate(
                avg_rating=Avg('review__rating'),
                review_count=Count('review')
            ).get(id=book_id)
            
            result = {
                'id': book.id,
                'title': book.title,
                'author': book.author.name,
                'avg_rating': float(book.avg_rating or 0),
                'review_count': book.review_count,
                'genres': [g.name for g in book.genres.all()]
            }
            cache.set(cache_key, result, settings.CACHE_TIMEOUT['BOOK_LIST'])
        
        return result

# Cache invalidation
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver

@receiver([post_save, post_delete], sender=Review)
def invalidate_book_cache(sender, instance, **kwargs):
    """Invalidate cache when reviews change."""
    cache_patterns = [
        f"book_stats:{instance.book.id}",
        "top_authors:*",
    ]
    
    # In production, use more sophisticated cache invalidation
    cache.clear()  # Simple approach for development
```

### 7. Performance Monitoring

#### Query Performance Middleware
```python
# middleware/query_performance.py
import time
from django.db import connection
from django.conf import settings

class QueryPerformanceMiddleware:
    """Monitor query performance in development."""
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        if not settings.DEBUG:
            return self.get_response(request)
        
        start_queries = len(connection.queries)
        start_time = time.time()
        
        response = self.get_response(request)
        
        end_time = time.time()
        end_queries = len(connection.queries)
        
        query_count = end_queries - start_queries
        total_time = end_time - start_time
        
        if query_count > 10:  # Alert for high query count
            print(f"WARNING: {request.path} executed {query_count} queries in {total_time:.3f}s")
        
        # Add headers for debugging
        response['X-Query-Count'] = str(query_count)
        response['X-Query-Time'] = f"{total_time:.3f}s"
        
        return response
```

## Performance Testing

### Load Testing Script
```python
# tests/test_performance.py
import time
from django.test import TestCase, TransactionTestCase
from django.test.utils import override_settings
from model_bakery import baker

class QueryPerformanceTest(TransactionTestCase):
    """Test query performance with realistic data."""
    
    def setUp(self):
        """Create test data."""
        # Create authors
        self.authors = baker.make(Author, _quantity=100)
        
        # Create books
        self.books = []
        for author in self.authors:
            books = baker.make(Book, author=author, _quantity=5)
            self.books.extend(books)
        
        # Create reviews
        for book in self.books:
            baker.make(Review, book=book, _quantity=10)
    
    def test_book_list_performance(self):
        """Test book list query performance."""
        start_time = time.time()
        
        # Simulate book list view
        books = Book.objects.select_related('author').prefetch_related('genres').annotate(
            avg_rating=Avg('review__rating'),
            review_count=Count('review')
        )[:50]
        
        # Force evaluation
        list(books)
        
        end_time = time.time()
        execution_time = end_time - start_time
        
        # Should complete within reasonable time
        self.assertLess(execution_time, 1.0, "Book list query too slow")
    
    def test_top_authors_performance(self):
        """Test top authors query performance."""
        start_time = time.time()
        
        top_authors = Author.objects.top_authors(limit=10)
        list(top_authors)  # Force evaluation
        
        end_time = time.time()
        execution_time = end_time - start_time
        
        self.assertLess(execution_time, 0.5, "Top authors query too slow")
    
    @override_settings(DEBUG=True)
    def test_query_count(self):
        """Test that queries don't exceed reasonable limits."""
        from django.db import connection
        
        connection.queries_log.clear()
        
        # Test book list with related data
        books = Book.objects.select_related('author').prefetch_related('genres')[:20]
        for book in books:
            _ = book.author.name
            _ = list(book.genres.all())
        
        query_count = len(connection.queries)
        
        # Should use minimal queries with proper prefetching
        self.assertLessEqual(query_count, 5, f"Too many queries: {query_count}")
```

## Evaluation Criteria

### Query Optimization (30%)
- Elimination of N+1 queries
- Proper use of select_related and prefetch_related
- Efficient complex queries
- Appropriate use of annotations and aggregations

### Database Design (25%)
- Strategic index placement
- Optimal foreign key relationships
- Consideration of query patterns
- Schema normalization balance

### Performance Improvement (20%)
- Measurable performance gains
- Scalability considerations
- Memory usage optimization
- Response time improvements

### Code Quality (15%)
- Clean, maintainable query code
- Proper documentation
- Error handling
- Testing coverage

### Monitoring & Analysis (10%)
- Performance measurement tools
- Query analysis capabilities
- Caching implementation
- Monitoring setup

## Submission Guidelines

### What to Submit
1. **Optimized Models**: Enhanced model classes with indexes
2. **Optimized Views**: Views with proper query optimization
3. **Query Utilities**: Helper classes for complex queries
4. **Performance Tests**: Test cases measuring improvements
5. **Migration Files**: Database schema optimizations
6. **Documentation**: Performance analysis and recommendations

### Performance Benchmarks
Include before/after metrics:
- Query execution time
- Number of database queries
- Memory usage
- Response time improvements

## Helpful Resources

- **Django ORM Optimization**: https://docs.djangoproject.com/en/stable/topics/db/optimization/
- **Database Indexing**: https://docs.djangoproject.com/en/stable/ref/models/indexes/
- **Query Expressions**: https://docs.djangoproject.com/en/stable/ref/models/expressions/
- **PostgreSQL Performance**: https://www.postgresql.org/docs/current/performance-tips.html

## Time Management Tips

- **Hour 1**: Analyze current performance and identify bottlenecks
- **Hour 2**: Implement query optimizations and add indexes
- **Hour 3**: Test improvements and implement caching

## Common Pitfalls to Avoid

- Over-indexing (too many indexes can slow writes)
- Not testing with realistic data volumes
- Ignoring query execution plans
- Premature optimization without measurement
- Not considering cache invalidation
- Missing composite indexes for common query patterns

Good luck optimizing your database queries! Focus on measuring performance before and after changes to demonstrate real improvements.
