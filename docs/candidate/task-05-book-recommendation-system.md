# Task 5: Book Recommendation System Design

**Time Allocation**: 1 hour discussion + 2 hours implementation  
**Difficulty Level**: Senior Level  
**Focus Areas**: System Design, Algorithm Implementation, Scalability

## Overview

Design and implement a book recommendation system for the DevTest catalog. This task evaluates your system design thinking, algorithm implementation skills, and ability to consider scalability and performance implications. The task combines architectural planning with practical implementation.

## Project Setup

Follow the [Running the Project guide](../setup/running-project.md) to start the application with DevContainer, Docker Compose, or GitHub Codespaces.

## Task Requirements

### Phase 1: System Design Discussion (1 hour)

#### Design Requirements
1. **Recommendation Types**
   - Content-based filtering (similar books)
   - Collaborative filtering (users who liked this also liked)
   - Hybrid approach combining both methods
   - Popular books recommendations
   - Genre-based recommendations

2. **Scalability Considerations**
   - Handle 1M+ books and 10M+ reviews
   - Real-time vs batch processing
   - Caching strategies
   - Database optimization
   - API performance

3. **Data Requirements**
   - User behavior tracking
   - Book similarity metrics
   - Rating patterns analysis
   - Genre preferences
   - Reading history

#### Discussion Points
- Algorithm selection and trade-offs
- Database schema changes needed
- Caching strategy design
- API endpoint planning
- Performance monitoring approach
- A/B testing considerations

### Phase 2: Implementation (2 hours)

#### Core Features (Required)

1. **Content-Based Recommendations**
   - Recommend books similar to a given book
   - Based on genres, author, and ratings
   - Implement similarity scoring algorithm

2. **Collaborative Filtering**
   - "Users who liked this also liked" recommendations
   - User-based or item-based collaborative filtering
   - Handle cold start problem

3. **Popular Books**
   - Trending books based on recent reviews
   - Top-rated books overall
   - Genre-specific popular books

4. **User Preferences**
   - Personalized recommendations based on user's reading history
   - Genre preference learning
   - Rating pattern analysis

#### Advanced Features (Optional)
- Machine learning integration
- Real-time recommendation updates
- A/B testing framework
- Recommendation explanation system
- Diversity and serendipity factors

## Implementation Guidelines

### 1. Database Schema Extensions

```python
# models.py - Add to existing models
from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone
from datetime import timedelta

class UserPreference(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    favorite_genres = models.ManyToManyField(Genre, blank=True)
    preferred_authors = models.ManyToManyField(Author, blank=True)
    avg_rating_given = models.DecimalField(max_digits=3, decimal_places=2, null=True)
    total_reviews = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

class BookSimilarity(models.Model):
    book1 = models.ForeignKey(Book, on_delete=models.CASCADE, related_name='similarity_from')
    book2 = models.ForeignKey(Book, on_delete=models.CASCADE, related_name='similarity_to')
    similarity_score = models.DecimalField(max_digits=5, decimal_places=4)
    calculation_date = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['book1', 'book2']
        indexes = [
            models.Index(fields=['book1', '-similarity_score']),
            models.Index(fields=['book2', '-similarity_score']),
        ]

class UserBookInteraction(models.Model):
    INTERACTION_TYPES = [
        ('view', 'Viewed'),
        ('review', 'Reviewed'),
        ('favorite', 'Favorited'),
        ('share', 'Shared'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    book = models.ForeignKey(Book, on_delete=models.CASCADE)
    interaction_type = models.CharField(max_length=20, choices=INTERACTION_TYPES)
    timestamp = models.DateTimeField(auto_now_add=True)
    weight = models.DecimalField(max_digits=3, decimal_places=2, default=1.0)
    
    class Meta:
        indexes = [
            models.Index(fields=['user', '-timestamp']),
            models.Index(fields=['book', '-timestamp']),
        ]

class RecommendationCache(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    book = models.ForeignKey(Book, on_delete=models.CASCADE, null=True, blank=True)
    recommendation_type = models.CharField(max_length=50)
    recommended_books = models.JSONField()  # List of book IDs with scores
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    
    class Meta:
        indexes = [
            models.Index(fields=['user', 'recommendation_type']),
            models.Index(fields=['book', 'recommendation_type']),
            models.Index(fields=['expires_at']),
        ]
```

### 2. Recommendation Engine Implementation

```python
# recommendations/engine.py
import math
from collections import defaultdict
from decimal import Decimal
from django.db.models import Avg, Count, Q
from django.utils import timezone
from datetime import timedelta

from devtest.app.models import Book, Review, Author, Genre, User
from .models import BookSimilarity, UserPreference, UserBookInteraction

class RecommendationEngine:
    """Main recommendation engine with multiple algorithms."""
    
    def __init__(self):
        self.cache_duration = timedelta(hours=24)
    
    def get_recommendations(self, user=None, book=None, recommendation_type='mixed', limit=10):
        """Get recommendations based on type and context."""
        if recommendation_type == 'content_based' and book:
            return self.content_based_recommendations(book, limit)
        elif recommendation_type == 'collaborative' and user:
            return self.collaborative_filtering(user, limit)
        elif recommendation_type == 'popular':
            return self.popular_books(limit)
        elif recommendation_type == 'personalized' and user:
            return self.personalized_recommendations(user, limit)
        else:
            return self.mixed_recommendations(user, book, limit)
    
    def content_based_recommendations(self, book, limit=10):
        """Recommend books similar to the given book."""
        # Check cache first
        cached = self._get_cached_recommendations(book=book, rec_type='content_based')
        if cached:
            return cached[:limit]
        
        # Calculate similarities if not cached
        similar_books = self._calculate_content_similarity(book)
        
        # Cache results
        self._cache_recommendations(
            book=book, 
            rec_type='content_based', 
            recommendations=similar_books
        )
        
        return similar_books[:limit]
    
    def _calculate_content_similarity(self, target_book):
        """Calculate content-based similarity scores."""
        all_books = Book.objects.exclude(id=target_book.id).select_related('author').prefetch_related('genres')
        similarities = []
        
        for book in all_books:
            score = self._content_similarity_score(target_book, book)
            if score > 0:
                similarities.append({
                    'book': book,
                    'score': score,
                    'reasons': self._get_similarity_reasons(target_book, book)
                })
        
        # Sort by score descending
        similarities.sort(key=lambda x: x['score'], reverse=True)
        return similarities
    
    def _content_similarity_score(self, book1, book2):
        """Calculate similarity score between two books."""
        score = 0.0
        
        # Author similarity (high weight)
        if book1.author == book2.author:
            score += 0.4
        
        # Genre similarity (medium weight)
        book1_genres = set(book1.genres.all())
        book2_genres = set(book2.genres.all())
        if book1_genres and book2_genres:
            genre_overlap = len(book1_genres.intersection(book2_genres))
            genre_union = len(book1_genres.union(book2_genres))
            genre_similarity = genre_overlap / genre_union if genre_union > 0 else 0
            score += genre_similarity * 0.3
        
        # Rating similarity (low weight)
        book1_avg = book1.review_set.aggregate(avg=Avg('rating'))['avg'] or 0
        book2_avg = book2.review_set.aggregate(avg=Avg('rating'))['avg'] or 0
        if book1_avg and book2_avg:
            rating_diff = abs(book1_avg - book2_avg)
            rating_similarity = max(0, 1 - (rating_diff / 4))  # Normalize to 0-1
            score += rating_similarity * 0.2
        
        # Review count similarity (very low weight)
        book1_reviews = book1.review_set.count()
        book2_reviews = book2.review_set.count()
        if book1_reviews > 0 and book2_reviews > 0:
            review_ratio = min(book1_reviews, book2_reviews) / max(book1_reviews, book2_reviews)
            score += review_ratio * 0.1
        
        return score
    
    def collaborative_filtering(self, user, limit=10):
        """Collaborative filtering recommendations."""
        # Get users with similar rating patterns
        similar_users = self._find_similar_users(user)
        
        # Get books liked by similar users
        recommended_books = self._get_books_from_similar_users(user, similar_users)
        
        return recommended_books[:limit]
    
    def _find_similar_users(self, target_user):
        """Find users with similar rating patterns."""
        target_reviews = Review.objects.filter(user=target_user).select_related('book')
        target_ratings = {review.book_id: review.rating for review in target_reviews}
        
        if not target_ratings:
            return []
        
        # Find users who reviewed the same books
        common_books = list(target_ratings.keys())
        other_users = User.objects.filter(
            review__book_id__in=common_books
        ).exclude(id=target_user.id).distinct()
        
        similarities = []
        for user in other_users:
            user_reviews = Review.objects.filter(
                user=user, 
                book_id__in=common_books
            ).select_related('book')
            user_ratings = {review.book_id: review.rating for review in user_reviews}
            
            # Calculate Pearson correlation
            similarity = self._pearson_correlation(target_ratings, user_ratings)
            if similarity > 0.1:  # Minimum similarity threshold
                similarities.append((user, similarity))
        
        # Sort by similarity descending
        similarities.sort(key=lambda x: x[1], reverse=True)
        return similarities[:50]  # Top 50 similar users
    
    def _pearson_correlation(self, ratings1, ratings2):
        """Calculate Pearson correlation coefficient."""
        common_books = set(ratings1.keys()).intersection(set(ratings2.keys()))
        
        if len(common_books) < 2:
            return 0
        
        sum1 = sum(ratings1[book] for book in common_books)
        sum2 = sum(ratings2[book] for book in common_books)
        
        sum1_sq = sum(ratings1[book] ** 2 for book in common_books)
        sum2_sq = sum(ratings2[book] ** 2 for book in common_books)
        
        sum_products = sum(ratings1[book] * ratings2[book] for book in common_books)
        
        n = len(common_books)
        numerator = sum_products - (sum1 * sum2 / n)
        denominator = math.sqrt((sum1_sq - sum1 ** 2 / n) * (sum2_sq - sum2 ** 2 / n))
        
        if denominator == 0:
            return 0
        
        return numerator / denominator
    
    def popular_books(self, limit=10, time_period_days=30):
        """Get popular books based on recent activity."""
        cutoff_date = timezone.now() - timedelta(days=time_period_days)
        
        popular = Book.objects.annotate(
            recent_review_count=Count(
                'review', 
                filter=Q(review__created_at__gte=cutoff_date)
            ),
            avg_rating=Avg('review__rating'),
            total_reviews=Count('review')
        ).filter(
            recent_review_count__gt=0
        ).order_by(
            '-recent_review_count', 
            '-avg_rating'
        )[:limit]
        
        return [{'book': book, 'score': book.recent_review_count} for book in popular]
    
    def personalized_recommendations(self, user, limit=10):
        """Generate personalized recommendations for a user."""
        # Combine multiple recommendation types
        content_recs = []
        collab_recs = self.collaborative_filtering(user, limit=5)
        popular_recs = self.popular_books(limit=5)
        
        # Get user's recent reviews to base content recommendations on
        recent_reviews = Review.objects.filter(
            user=user, 
            rating__gte=4
        ).order_by('-created_at')[:3]
        
        for review in recent_reviews:
            content_recs.extend(
                self.content_based_recommendations(review.book, limit=3)
            )
        
        # Combine and deduplicate
        all_recs = []
        seen_books = set()
        
        # Prioritize collaborative filtering
        for rec in collab_recs:
            if rec['book'].id not in seen_books:
                all_recs.append(rec)
                seen_books.add(rec['book'].id)
        
        # Add content-based recommendations
        for rec in content_recs:
            if rec['book'].id not in seen_books and len(all_recs) < limit:
                all_recs.append(rec)
                seen_books.add(rec['book'].id)
        
        # Fill with popular books if needed
        for rec in popular_recs:
            if rec['book'].id not in seen_books and len(all_recs) < limit:
                all_recs.append(rec)
                seen_books.add(rec['book'].id)
        
        return all_recs[:limit]
    
    def _get_cached_recommendations(self, user=None, book=None, rec_type=''):
        """Get cached recommendations if available and not expired."""
        from .models import RecommendationCache
        
        try:
            cache_entry = RecommendationCache.objects.get(
                user=user,
                book=book,
                recommendation_type=rec_type,
                expires_at__gt=timezone.now()
            )
            
            # Convert cached data back to recommendation format
            book_ids = [item['book_id'] for item in cache_entry.recommended_books]
            books = Book.objects.filter(id__in=book_ids).select_related('author')
            book_dict = {book.id: book for book in books}
            
            recommendations = []
            for item in cache_entry.recommended_books:
                if item['book_id'] in book_dict:
                    recommendations.append({
                        'book': book_dict[item['book_id']],
                        'score': item['score'],
                        'reasons': item.get('reasons', [])
                    })
            
            return recommendations
        except RecommendationCache.DoesNotExist:
            return None
    
    def _cache_recommendations(self, user=None, book=None, rec_type='', recommendations=None):
        """Cache recommendations for future use."""
        from .models import RecommendationCache
        
        if not recommendations:
            return
        
        # Convert recommendations to cacheable format
        cached_data = []
        for rec in recommendations:
            cached_data.append({
                'book_id': rec['book'].id,
                'score': float(rec['score']),
                'reasons': rec.get('reasons', [])
            })
        
        # Save to cache
        RecommendationCache.objects.update_or_create(
            user=user,
            book=book,
            recommendation_type=rec_type,
            defaults={
                'recommended_books': cached_data,
                'expires_at': timezone.now() + self.cache_duration
            }
        )
```

### 3. API Endpoints

```python
# views.py or api/views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .recommendations.engine import RecommendationEngine
from .models import Book

@api_view(['GET'])
def book_recommendations(request, book_id):
    """Get recommendations for a specific book."""
    try:
        book = Book.objects.get(id=book_id)
        engine = RecommendationEngine()
        recommendations = engine.content_based_recommendations(book, limit=10)
        
        data = []
        for rec in recommendations:
            data.append({
                'id': rec['book'].id,
                'title': rec['book'].title,
                'author': rec['book'].author.name,
                'score': rec['score'],
                'reasons': rec.get('reasons', [])
            })
        
        return Response(data)
    except Book.DoesNotExist:
        return Response({'error': 'Book not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_recommendations(request):
    """Get personalized recommendations for the authenticated user."""
    engine = RecommendationEngine()
    recommendations = engine.personalized_recommendations(request.user, limit=10)
    
    data = []
    for rec in recommendations:
        data.append({
            'id': rec['book'].id,
            'title': rec['book'].title,
            'author': rec['book'].author.name,
            'score': rec['score'],
            'recommendation_type': 'personalized'
        })
    
    return Response(data)

@api_view(['GET'])
def popular_books(request):
    """Get popular books."""
    engine = RecommendationEngine()
    popular = engine.popular_books(limit=10)
    
    data = []
    for rec in popular:
        data.append({
            'id': rec['book'].id,
            'title': rec['book'].title,
            'author': rec['book'].author.name,
            'popularity_score': rec['score']
        })
    
    return Response(data)
```

### 4. Management Commands

```python
# management/commands/update_recommendations.py
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from devtest.app.models import Book
from recommendations.engine import RecommendationEngine

class Command(BaseCommand):
    help = 'Update recommendation cache for all users and books'
    
    def add_arguments(self, parser):
        parser.add_argument('--users', action='store_true', help='Update user recommendations')
        parser.add_argument('--books', action='store_true', help='Update book recommendations')
        parser.add_argument('--batch-size', type=int, default=100, help='Batch size for processing')
    
    def handle(self, *args, **options):
        engine = RecommendationEngine()
        
        if options['users']:
            self.update_user_recommendations(engine, options['batch_size'])
        
        if options['books']:
            self.update_book_recommendations(engine, options['batch_size'])
    
    def update_user_recommendations(self, engine, batch_size):
        users = User.objects.filter(review__isnull=False).distinct()
        total = users.count()
        
        self.stdout.write(f'Updating recommendations for {total} users...')
        
        for i in range(0, total, batch_size):
            batch = users[i:i+batch_size]
            for user in batch:
                try:
                    engine.personalized_recommendations(user, limit=20)
                    self.stdout.write(f'Updated recommendations for user {user.id}')
                except Exception as e:
                    self.stdout.write(f'Error updating user {user.id}: {e}')
    
    def update_book_recommendations(self, engine, batch_size):
        books = Book.objects.filter(review__isnull=False).distinct()
        total = books.count()
        
        self.stdout.write(f'Updating recommendations for {total} books...')
        
        for i in range(0, total, batch_size):
            batch = books[i:i+batch_size]
            for book in batch:
                try:
                    engine.content_based_recommendations(book, limit=20)
                    self.stdout.write(f'Updated recommendations for book {book.id}')
                except Exception as e:
                    self.stdout.write(f'Error updating book {book.id}: {e}')
```

## Evaluation Criteria

### System Design (30%)
- Algorithm selection and justification
- Scalability considerations
- Database design decisions
- Caching strategy
- Performance implications

### Implementation Quality (25%)
- Code organization and structure
- Algorithm correctness
- Error handling
- Performance optimization
- Documentation

### Technical Depth (20%)
- Understanding of recommendation algorithms
- Database query optimization
- Caching implementation
- API design
- Testing approach

### Scalability Awareness (15%)
- Handling large datasets
- Performance monitoring
- Batch processing considerations
- Memory usage optimization
- Database indexing

### Innovation (10%)
- Creative algorithm combinations
- Novel similarity metrics
- User experience enhancements
- A/B testing considerations
- Machine learning integration

## Testing Your Implementation

### Manual Testing
```python
# Test in Django shell
from recommendations.engine import RecommendationEngine
from devtest.app.models import Book, User

engine = RecommendationEngine()

# Test content-based recommendations
book = Book.objects.first()
recommendations = engine.content_based_recommendations(book, limit=5)
print(f"Recommendations for '{book.title}':")
for rec in recommendations:
    print(f"  - {rec['book'].title} (score: {rec['score']:.3f})")

# Test personalized recommendations
user = User.objects.first()
personal_recs = engine.personalized_recommendations(user, limit=5)
print(f"\nPersonalized recommendations for {user.username}:")
for rec in personal_recs:
    print(f"  - {rec['book'].title} (score: {rec['score']:.3f})")
```

### Performance Testing
```bash
# Update recommendations for all users/books
python manage.py update_recommendations --users --books

# Monitor database queries
python manage.py shell
>>> from django.db import connection
>>> # Run recommendation code
>>> print(len(connection.queries))
```

## Submission Guidelines

### What to Submit
1. System design document with algorithm explanations
2. Database schema changes (migrations)
3. Recommendation engine implementation
4. API endpoints
5. Management commands
6. Performance analysis and optimization notes
7. Testing results and benchmarks

### Documentation Requirements
- Algorithm explanations and trade-offs
- Scalability considerations and solutions
- Performance benchmarks
- API documentation
- Future enhancement suggestions

## Helpful Resources

- **Collaborative Filtering**: https://en.wikipedia.org/wiki/Collaborative_filtering
- **Content-Based Filtering**: https://en.wikipedia.org/wiki/Recommender_system#Content-based_filtering
- **Django Aggregation**: https://docs.djangoproject.com/en/stable/topics/db/aggregation/
- **Database Indexing**: https://docs.djangoproject.com/en/stable/ref/models/indexes/

## Time Management Tips

- **Hour 1**: System design discussion and planning
- **Hour 2**: Core algorithm implementation
- **Hour 3**: API endpoints, caching, and optimization

## Common Pitfalls to Avoid

- Not considering cold start problems
- Ignoring performance implications of algorithms
- Not implementing proper caching
- Missing database indexes
- Not handling edge cases (no reviews, new users)
- Over-engineering the initial solution
- Not considering recommendation diversity

Good luck designing your recommendation system! Focus on balancing algorithm effectiveness with system performance and scalability.
