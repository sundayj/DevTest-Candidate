# Task 10: Performance Monitoring & Caching Strategy

**Time Allocation**: 2-3 hours  
**Difficulty Level**: Senior-Level  
**Focus Areas**: Performance Optimization, Caching, Monitoring, System Architecture

## Overview

Implement a comprehensive performance monitoring and caching strategy for the DevTest book catalog application. This task evaluates your understanding of application performance, caching mechanisms, monitoring tools, and optimization techniques. You'll need to identify performance bottlenecks, implement various caching layers, and create monitoring dashboards.

## Project Setup

Follow the [Running the Project guide](../setup/running-project.md) to start the application with DevContainer, Docker Compose, or GitHub Codespaces.

## Task Requirements

### Core Performance Features (Required)

1. **Performance Monitoring System**
   - Application performance metrics collection
   - Database query monitoring and analysis
   - Response time tracking
   - Memory and CPU usage monitoring
   - Error rate and exception tracking

2. **Multi-Level Caching Strategy**
   - Database query result caching
   - Template fragment caching
   - Full page caching for static content
   - API response caching
   - Session-based caching

3. **Cache Management Interface**
   - Cache statistics dashboard
   - Cache invalidation controls
   - Cache warming functionality
   - Cache hit/miss ratio monitoring
   - Cache size and memory usage tracking

4. **Performance Dashboard**
   - Real-time performance metrics
   - Historical performance trends
   - Slow query identification
   - Resource usage visualization
   - Performance alerts and notifications

### Advanced Features (Optional)

- Redis cluster setup for distributed caching
- CDN integration for static assets
- Database connection pooling optimization
- Async task performance monitoring
- Load testing integration
- Performance regression detection

## Implementation Guidelines

### 1. Performance Monitoring Setup

#### Django Debug Toolbar Integration
```python
# settings.py - Add performance monitoring
import os

# Debug toolbar for development
if DEBUG:
    INSTALLED_APPS += ['debug_toolbar']
    MIDDLEWARE += ['debug_toolbar.middleware.DebugToolbarMiddleware']
    
    DEBUG_TOOLBAR_CONFIG = {
        'SHOW_TOOLBAR_CALLBACK': lambda request: True,
        'SHOW_COLLAPSED': True,
        'PROFILER_MAX_DEPTH': 10,
    }

# Performance monitoring
INSTALLED_APPS += [
    'django_extensions',
    'silk',  # For SQL query profiling
]

MIDDLEWARE += [
    'silk.middleware.SilkyMiddleware',
]

# Silk configuration
SILKY_PYTHON_PROFILER = True
SILKY_PYTHON_PROFILER_BINARY = True
SILKY_AUTHENTICATION = True
SILKY_AUTHORISATION = True
```

#### Custom Performance Middleware
```python
# middleware.py - Performance tracking middleware
import time
import logging
from django.utils.deprecation import MiddlewareMixin
from django.core.cache import cache
from django.db import connection

logger = logging.getLogger(__name__)

class PerformanceMonitoringMiddleware(MiddlewareMixin):
    def process_request(self, request):
        request.start_time = time.time()
        request.start_queries = len(connection.queries)
        
    def process_response(self, request, response):
        if hasattr(request, 'start_time'):
            duration = time.time() - request.start_time
            query_count = len(connection.queries) - request.start_queries
            
            # Log performance metrics
            logger.info(f"Request: {request.path} | "
                       f"Duration: {duration:.3f}s | "
                       f"Queries: {query_count} | "
                       f"Status: {response.status_code}")
            
            # Store metrics in cache for dashboard
            self.store_performance_metrics(request, duration, query_count, response.status_code)
            
        return response
    
    def store_performance_metrics(self, request, duration, query_count, status_code):
        metrics_key = f"performance_metrics_{request.path.replace('/', '_')}"
        metrics = cache.get(metrics_key, [])
        
        metrics.append({
            'timestamp': time.time(),
            'duration': duration,
            'query_count': query_count,
            'status_code': status_code,
            'path': request.path,
        })
        
        # Keep only last 100 entries
        metrics = metrics[-100:]
        cache.set(metrics_key, metrics, 3600)  # 1 hour
```

### 2. Caching Implementation

#### Database Query Caching
```python
# models.py - Add caching to model methods
from django.core.cache import cache
from django.db import models
from django.utils import timezone
import hashlib

class CachedQueryMixin:
    @classmethod
    def get_cached_queryset(cls, cache_key, queryset_func, timeout=300):
        """Generic method for caching querysets"""
        cached_result = cache.get(cache_key)
        if cached_result is None:
            cached_result = list(queryset_func())
            cache.set(cache_key, cached_result, timeout)
        return cached_result

class Author(models.Model, CachedQueryMixin):
    # ... existing fields ...
    
    @classmethod
    def get_top_authors_cached(cls, limit=10):
        cache_key = f"top_authors_{limit}"
        return cls.get_cached_queryset(
            cache_key,
            lambda: cls.objects.annotate(
                avg_rating=models.Avg('book__review__rating')
            ).filter(avg_rating__isnull=False).order_by('-avg_rating')[:limit],
            timeout=600  # 10 minutes
        )
    
    @classmethod
    def get_author_stats_cached(cls, author_id):
        cache_key = f"author_stats_{author_id}"
        cached_stats = cache.get(cache_key)
        
        if cached_stats is None:
            author = cls.objects.get(id=author_id)
            cached_stats = {
                'book_count': author.book_set.count(),
                'avg_rating': author.book_set.aggregate(
                    avg_rating=models.Avg('review__rating')
                )['avg_rating'] or 0,
                'total_reviews': author.book_set.aggregate(
                    total_reviews=models.Count('review')
                )['total_reviews'],
            }
            cache.set(cache_key, cached_stats, 300)  # 5 minutes
            
        return cached_stats

class Book(models.Model, CachedQueryMixin):
    # ... existing fields ...
    
    @classmethod
    def get_popular_books_cached(cls, limit=20):
        cache_key = f"popular_books_{limit}"
        return cls.get_cached_queryset(
            cache_key,
            lambda: cls.objects.annotate(
                avg_rating=models.Avg('review__rating'),
                review_count=models.Count('review')
            ).filter(review_count__gte=1).order_by('-avg_rating', '-review_count')[:limit],
            timeout=900  # 15 minutes
        )
    
    def get_cached_reviews(self):
        cache_key = f"book_reviews_{self.id}"
        return cache.get_or_set(
            cache_key,
            lambda: list(self.review_set.select_related('user').all()),
            timeout=300
        )
```

#### Template Fragment Caching
```html
<!-- templates/app/book_list.html -->
{% load cache %}

<div class="book-list">
    {% cache 600 popular_books %}
    <div class="popular-books-section">
        <h3>Popular Books</h3>
        {% for book in popular_books %}
            {% cache 300 book_card book.id book.updated_at %}
            <div class="book-card">
                <h4>{{ book.title }}</h4>
                <p>by {{ book.author.name }}</p>
                <div class="rating">
                    Rating: {{ book.avg_rating|floatformat:1 }}
                    ({{ book.review_count }} reviews)
                </div>
            </div>
            {% endcache %}
        {% endfor %}
    </div>
    {% endcache %}
    
    {% cache 300 book_stats %}
    <div class="book-statistics">
        <h4>Library Statistics</h4>
        <p>Total Books: {{ total_books }}</p>
        <p>Total Authors: {{ total_authors }}</p>
        <p>Total Reviews: {{ total_reviews }}</p>
    </div>
    {% endcache %}
</div>
```

#### API Response Caching
```python
# views.py - API caching decorators
from django.views.decorators.cache import cache_page
from django.views.decorators.vary import vary_on_headers
from django.utils.decorators import method_decorator
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.core.cache import cache
import json

def cache_api_response(timeout=300, key_prefix='api'):
    """Custom decorator for API response caching"""
    def decorator(view_func):
        def wrapper(request, *args, **kwargs):
            # Create cache key based on request parameters
            cache_key = f"{key_prefix}_{request.path}_{hash(str(request.GET))}"
            
            cached_response = cache.get(cache_key)
            if cached_response:
                return Response(cached_response)
            
            response = view_func(request, *args, **kwargs)
            
            if response.status_code == 200:
                cache.set(cache_key, response.data, timeout)
            
            return response
        return wrapper
    return decorator

@api_view(['GET'])
@cache_api_response(timeout=600, key_prefix='books_api')
def book_list_api(request):
    """Cached API endpoint for book list"""
    books = Book.get_popular_books_cached(limit=50)
    serialized_books = [
        {
            'id': book.id,
            'title': book.title,
            'author': book.author.name,
            'avg_rating': book.avg_rating,
            'review_count': book.review_count,
        }
        for book in books
    ]
    return Response(serialized_books)

@method_decorator(cache_page(300), name='dispatch')
@method_decorator(vary_on_headers('User-Agent'), name='dispatch')
class BookDetailView(DetailView):
    model = Book
    template_name = 'app/book_detail.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        book = self.object
        
        # Use cached methods
        context['reviews'] = book.get_cached_reviews()
        context['author_stats'] = Author.get_author_stats_cached(book.author.id)
        context['similar_books'] = self.get_similar_books_cached(book)
        
        return context
    
    def get_similar_books_cached(self, book):
        cache_key = f"similar_books_{book.id}"
        return cache.get_or_set(
            cache_key,
            lambda: Book.objects.filter(
                genre__in=book.genre.all()
            ).exclude(id=book.id)[:5],
            timeout=600
        )
```

### 3. Cache Management System

#### Cache Management Views
```python
# views.py - Cache management interface
from django.contrib.admin.views.decorators import staff_member_required
from django.shortcuts import render
from django.http import JsonResponse
from django.core.cache import cache
from django.core.cache.utils import make_template_fragment_key
import redis
import json

@staff_member_required
def cache_dashboard(request):
    """Cache management dashboard"""
    cache_stats = get_cache_statistics()
    return render(request, 'admin/cache_dashboard.html', {
        'cache_stats': cache_stats,
        'cache_keys': get_cache_keys_sample(),
    })

@staff_member_required
def cache_clear(request):
    """Clear specific cache or all cache"""
    if request.method == 'POST':
        cache_type = request.POST.get('cache_type', 'all')
        
        if cache_type == 'all':
            cache.clear()
            message = "All cache cleared successfully"
        elif cache_type == 'templates':
            clear_template_cache()
            message = "Template cache cleared successfully"
        elif cache_type == 'queries':
            clear_query_cache()
            message = "Query cache cleared successfully"
        else:
            cache_key = request.POST.get('cache_key')
            cache.delete(cache_key)
            message = f"Cache key '{cache_key}' cleared successfully"
        
        return JsonResponse({'success': True, 'message': message})
    
    return JsonResponse({'success': False, 'message': 'Invalid request'})

def get_cache_statistics():
    """Get comprehensive cache statistics"""
    try:
        # For Redis backend
        r = redis.Redis(host='localhost', port=6379, db=1)
        info = r.info()
        
        return {
            'memory_usage': info.get('used_memory_human', 'N/A'),
            'total_keys': r.dbsize(),
            'hit_rate': calculate_hit_rate(),
            'evicted_keys': info.get('evicted_keys', 0),
            'expired_keys': info.get('expired_keys', 0),
            'connected_clients': info.get('connected_clients', 0),
        }
    except:
        return {
            'memory_usage': 'N/A',
            'total_keys': 'N/A',
            'hit_rate': 'N/A',
            'evicted_keys': 'N/A',
            'expired_keys': 'N/A',
            'connected_clients': 'N/A',
        }

def calculate_hit_rate():
    """Calculate cache hit rate from stored metrics"""
    hits = cache.get('cache_hits', 0)
    misses = cache.get('cache_misses', 0)
    total = hits + misses
    
    if total == 0:
        return 0
    
    return round((hits / total) * 100, 2)

def clear_template_cache():
    """Clear template fragment cache"""
    template_keys = [
        make_template_fragment_key('popular_books'),
        make_template_fragment_key('book_stats'),
        # Add more template fragment keys as needed
    ]
    
    for key in template_keys:
        cache.delete(key)

def clear_query_cache():
    """Clear query-related cache keys"""
    query_cache_patterns = [
        'top_authors_*',
        'popular_books_*',
        'author_stats_*',
        'book_reviews_*',
        'similar_books_*',
    ]
    
    # This would require a more sophisticated implementation
    # depending on your cache backend
    pass
```

#### Cache Warming System
```python
# management/commands/warm_cache.py
from django.core.management.base import BaseCommand
from django.core.cache import cache
from app.models import Book, Author, Genre
import time

class Command(BaseCommand):
    help = 'Warm up application cache with frequently accessed data'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--type',
            choices=['all', 'books', 'authors', 'stats'],
            default='all',
            help='Type of cache to warm up'
        )
    
    def handle(self, *args, **options):
        cache_type = options['type']
        
        self.stdout.write('Starting cache warming...')
        start_time = time.time()
        
        if cache_type in ['all', 'books']:
            self.warm_book_cache()
        
        if cache_type in ['all', 'authors']:
            self.warm_author_cache()
        
        if cache_type in ['all', 'stats']:
            self.warm_statistics_cache()
        
        duration = time.time() - start_time
        self.stdout.write(
            self.style.SUCCESS(
                f'Cache warming completed in {duration:.2f} seconds'
            )
        )
    
    def warm_book_cache(self):
        self.stdout.write('Warming book cache...')
        
        # Popular books
        Book.get_popular_books_cached(limit=20)
        Book.get_popular_books_cached(limit=50)
        
        # Individual book details
        popular_books = Book.objects.all()[:20]
        for book in popular_books:
            book.get_cached_reviews()
            Author.get_author_stats_cached(book.author.id)
    
    def warm_author_cache(self):
        self.stdout.write('Warming author cache...')
        
        # Top authors
        Author.get_top_authors_cached(limit=10)
        Author.get_top_authors_cached(limit=20)
        
        # Author statistics
        authors = Author.objects.all()[:50]
        for author in authors:
            Author.get_author_stats_cached(author.id)
    
    def warm_statistics_cache(self):
        self.stdout.write('Warming statistics cache...')
        
        # General statistics
        cache.set('total_books', Book.objects.count(), 3600)
        cache.set('total_authors', Author.objects.count(), 3600)
        cache.set('total_genres', Genre.objects.count(), 3600)
```

### 4. Performance Dashboard

#### Dashboard Template
```html
<!-- templates/admin/cache_dashboard.html -->
{% extends "admin/base_site.html" %}
{% load static %}

{% block title %}Performance & Cache Dashboard{% endblock %}

{% block extrahead %}
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<style>
.dashboard-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    margin: 20px 0;
}

.dashboard-card {
    background: white;
    border: 1px solid #ddd;
    border-radius: 8px;
    padding: 20px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.metric-value {
    font-size: 2em;
    font-weight: bold;
    color: #2196F3;
}

.cache-controls {
    margin: 20px 0;
}

.cache-controls button {
    margin-right: 10px;
    padding: 8px 16px;
    background: #f44336;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.cache-controls button:hover {
    background: #d32f2f;
}
</style>
{% endblock %}

{% block content %}
<h1>Performance & Cache Dashboard</h1>

<div class="dashboard-grid">
    <div class="dashboard-card">
        <h3>Cache Statistics</h3>
        <div class="metric-value">{{ cache_stats.hit_rate }}%</div>
        <p>Cache Hit Rate</p>
        
        <p><strong>Memory Usage:</strong> {{ cache_stats.memory_usage }}</p>
        <p><strong>Total Keys:</strong> {{ cache_stats.total_keys }}</p>
        <p><strong>Connected Clients:</strong> {{ cache_stats.connected_clients }}</p>
    </div>
    
    <div class="dashboard-card">
        <h3>Performance Metrics</h3>
        <canvas id="performanceChart" width="400" height="200"></canvas>
    </div>
    
    <div class="dashboard-card">
        <h3>Database Queries</h3>
        <canvas id="queryChart" width="400" height="200"></canvas>
    </div>
    
    <div class="dashboard-card">
        <h3>Response Times</h3>
        <canvas id="responseTimeChart" width="400" height="200"></canvas>
    </div>
</div>

<div class="cache-controls">
    <h3>Cache Management</h3>
    <button onclick="clearCache('all')">Clear All Cache</button>
    <button onclick="clearCache('templates')">Clear Template Cache</button>
    <button onclick="clearCache('queries')">Clear Query Cache</button>
    <button onclick="warmCache()">Warm Cache</button>
</div>

<div class="dashboard-card">
    <h3>Recent Cache Keys</h3>
    <ul>
        {% for key in cache_keys %}
        <li>
            {{ key }}
            <button onclick="clearCacheKey('{{ key }}')">Clear</button>
        </li>
        {% endfor %}
    </ul>
</div>

<script>
// Performance metrics chart
const performanceCtx = document.getElementById('performanceChart').getContext('2d');
const performanceChart = new Chart(performanceCtx, {
    type: 'line',
    data: {
        labels: ['1h ago', '45m ago', '30m ago', '15m ago', 'Now'],
        datasets: [{
            label: 'Average Response Time (ms)',
            data: [120, 135, 98, 110, 105],
            borderColor: 'rgb(75, 192, 192)',
            tension: 0.1
        }]
    },
    options: {
        responsive: true,
        scales: {
            y: {
                beginAtZero: true
            }
        }
    }
});

// Query count chart
const queryCtx = document.getElementById('queryChart').getContext('2d');
const queryChart = new Chart(queryCtx, {
    type: 'bar',
    data: {
        labels: ['Books', 'Authors', 'Reviews', 'Genres'],
        datasets: [{
            label: 'Average Queries per Request',
            data: [3.2, 1.8, 2.5, 1.1],
            backgroundColor: [
                'rgba(255, 99, 132, 0.2)',
                'rgba(54, 162, 235, 0.2)',
                'rgba(255, 205, 86, 0.2)',
                'rgba(75, 192, 192, 0.2)'
            ],
            borderColor: [
                'rgba(255, 99, 132, 1)',
                'rgba(54, 162, 235, 1)',
                'rgba(255, 205, 86, 1)',
                'rgba(75, 192, 192, 1)'
            ],
            borderWidth: 1
        }]
    },
    options: {
        responsive: true,
        scales: {
            y: {
                beginAtZero: true
            }
        }
    }
});

// Response time distribution
const responseTimeCtx = document.getElementById('responseTimeChart').getContext('2d');
const responseTimeChart = new Chart(responseTimeCtx, {
    type: 'doughnut',
    data: {
        labels: ['< 100ms', '100-500ms', '500ms-1s', '> 1s'],
        datasets: [{
            data: [65, 25, 8, 2],
            backgroundColor: [
                '#4CAF50',
                '#FFC107',
                '#FF9800',
                '#F44336'
            ]
        }]
    },
    options: {
        responsive: true
    }
});

// Cache management functions
function clearCache(type) {
    if (confirm(`Are you sure you want to clear ${type} cache?`)) {
        fetch('{% url "cache_clear" %}', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'X-CSRFToken': '{{ csrf_token }}'
            },
            body: `cache_type=${type}`
        })
        .then(response => response.json())
        .then(data => {
            alert(data.message);
            if (data.success) {
                location.reload();
            }
        });
    }
}

function clearCacheKey(key) {
    if (confirm(`Clear cache key: ${key}?`)) {
        fetch('{% url "cache_clear" %}', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'X-CSRFToken': '{{ csrf_token }}'
            },
            body: `cache_key=${key}`
        })
        .then(response => response.json())
        .then(data => {
            alert(data.message);
            if (data.success) {
                location.reload();
            }
        });
    }
}

function warmCache() {
    alert('Cache warming started. This may take a few minutes.');
    // In a real implementation, this would trigger the management command
}

// Auto-refresh dashboard every 30 seconds
setInterval(() => {
    location.reload();
}, 30000);
</script>
{% endblock %}
```

### 5. Redis Configuration

#### Docker Compose Redis Setup
```yaml
# docker-compose.yml - Add Redis service
version: '3.8'

services:
  web:
    # ... existing web service configuration
    depends_on:
      - db
      - redis
    environment:
      - REDIS_URL=redis://redis:6379/1

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru

volumes:
  redis_data:
```

#### Redis Cache Configuration
```python
# settings.py - Redis cache configuration
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': os.environ.get('REDIS_URL', 'redis://127.0.0.1:6379/1'),
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'SERIALIZER': 'django_redis.serializers.json.JSONSerializer',
            'COMPRESSOR': 'django_redis.compressors.zlib.ZlibCompressor',
            'CONNECTION_POOL_KWARGS': {
                'max_connections': 20,
                'retry_on_timeout': True,
            }
        },
        'KEY_PREFIX': 'devtest',
        'TIMEOUT': 300,  # 5 minutes default
    }
}

# Session cache
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'

# Cache middleware
MIDDLEWARE = [
    'django.middleware.cache.UpdateCacheMiddleware',
    # ... other middleware
    'django.middleware.cache.FetchFromCacheMiddleware',
]

CACHE_MIDDLEWARE_ALIAS = 'default'
CACHE_MIDDLEWARE_SECONDS = 300
CACHE_MIDDLEWARE_KEY_PREFIX = 'devtest'
```

## Testing Guidelines

### Performance Testing
```python
# tests/test_performance.py
from django.test import TestCase, TransactionTestCase
from django.test.utils import override_settings
from django.core.cache import cache
from django.urls import reverse
from django.contrib.auth.models import User
from app.models import Book, Author
import time

class PerformanceTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user('testuser', 'test@example.com', 'password')
        self.author = Author.objects.create(name='Test Author')
        self.books = [
            Book.objects.create(
                title=f'Test Book {i}',
                author=self.author,
                isbn=f'123456789{i:03d}',
                publication_date='2023-01-01'
            )
            for i in range(100)
        ]
    
    def test_book_list_performance(self):
        """Test book list page performance"""
        start_time = time.time()
        response = self.client.get(reverse('book_list'))
        duration = time.time() - start_time
        
        self.assertEqual(response.status_code, 200)
        self.assertLess(duration, 1.0, "Book list should load in under 1 second")
    
    def test_cached_vs_uncached_performance(self):
        """Compare cached vs uncached query performance"""
        # Clear cache
        cache.clear()
        
        # Uncached query
        start_time = time.time()
        Book.get_popular_books_cached(limit=20)
        uncached_duration = time.time() - start_time
        
        # Cached query
        start_time = time.time()
        Book.get_popular_books_cached(limit=20)
        cached_duration = time.time() - start_time
        
        self.assertLess(cached_duration, uncached_duration,
                       "Cached query should be faster than uncached")
    
    def test_cache_hit_rate(self):
        """Test cache hit rate tracking"""
        cache.clear()
        
        # Generate some cache hits and misses
        for i in range(10):
            Book.get_popular_books_cached(limit=20)
        
        # This would require implementing hit rate tracking
        # hit_rate = calculate_hit_rate()
        # self.assertGreater(hit_rate, 80, "Cache hit rate should be above 80%")

class CacheTestCase(TestCase):
    def test_cache_invalidation(self):
        """Test cache invalidation when data changes"""
        # Cache some data
        popular_books = Book.get_popular_books_cached(limit=10)
        self.assertTrue(len(popular_books) >= 0)
        
        # Modify data
        new_book = Book.objects.create(
            title='New Book',
            author=self.author,
            isbn='9999999999',
            publication_date='2023-01-01'
        )
        
        # Cache should be invalidated (implement cache invalidation signals)
        # updated_books = Book.get_popular_books_cached(limit=10)
        # self.assertIn(new_book, updated_books)
    
    def test_template_fragment_caching(self):
        """Test template fragment caching"""
        response1 = self.client.get(reverse('book_list'))
        response2 = self.client.get(reverse('book_list'))
        
        # Both responses should be identical due to caching
        self.assertEqual(response1.content, response2.content)
```

### Load Testing Script
```python
# scripts/load_test.py
import requests
import time
import threading
import statistics
from concurrent.futures import ThreadPoolExecutor

class LoadTester:
    def __init__(self, base_url='http://localhost:8001'):
        self.base_url = base_url
        self.response_times = []
        self.errors = []
    
    def make_request(self, endpoint):
        """Make a single request and record response time"""
        try:
            start_time = time.time()
            response = requests.get(f"{self.base_url}{endpoint}")
            duration = time.time() - start_time
            
            self.response_times.append(duration)
            
            if response.status_code != 200:
                self.errors.append(f"Status {response.status_code} for {endpoint}")
                
        except Exception as e:
            self.errors.append(f"Exception for {endpoint}: {str(e)}")
    
    def run_load_test(self, endpoints, concurrent_users=10, requests_per_user=20):
        """Run load test with multiple concurrent users"""
        print(f"Starting load test with {concurrent_users} users, {requests_per_user} requests each")
        
        with ThreadPoolExecutor(max_workers=concurrent_users) as executor:
            futures = []
            
            for user in range(concurrent_users):
                for request in range(requests_per_user):
                    endpoint = endpoints[request % len(endpoints)]
                    future = executor.submit(self.make_request, endpoint)
                    futures.append(future)
            
            # Wait for all requests to complete
            for future in futures:
                future.result()
        
        self.print_results()
    
    def print_results(self):
        """Print load test results"""
        if self.response_times:
            avg_time = statistics.mean(self.response_times)
            median_time = statistics.median(self.response_times)
            max_time = max(self.response_times)
            min_time = min(self.response_times)
            
            print(f"\nLoad Test Results:")
            print(f"Total Requests: {len(self.response_times)}")
            print(f"Average Response Time: {avg_time:.3f}s")
            print(f"Median Response Time: {median_time:.3f}s")
            print(f"Min Response Time: {min_time:.3f}s")
            print(f"Max Response Time: {max_time:.3f}s")
            print(f"Errors: {len(self.errors)}")
            
            if self.errors:
                print("\nErrors:")
                for error in self.errors[:10]:  # Show first 10 errors
                    print(f"  - {error}")

if __name__ == '__main__':
    tester = LoadTester()
    endpoints = [
        '/',
        '/books/',
        '/authors/',
        '/api/books/',
        '/admin/',
    ]
    
    tester.run_load_test(endpoints, concurrent_users=20, requests_per_user=10)
```

## Evaluation Criteria

### Technical Implementation (40%)

**Excellent (90-100%)**
- Implements comprehensive multi-level caching strategy
- Proper cache invalidation and warming mechanisms
- Efficient performance monitoring with detailed metrics
- Redis integration with optimal configuration
- Custom middleware for performance tracking

**Good (70-89%)**
- Implements basic caching for queries and templates
- Basic performance monitoring setup
- Cache management interface with clear/warm functionality
- Some optimization of database queries
- Performance testing implementation

**Satisfactory (50-69%)**
- Basic template or query caching implementation
- Simple performance metrics collection
- Basic cache clearing functionality
- Some attempt at performance optimization
- Limited monitoring capabilities

**Needs Improvement (0-49%)**
- Minimal or incorrect caching implementation
- No performance monitoring
- Poor understanding of caching concepts
- No optimization strategies
- Missing key requirements

### Code Quality & Architecture (25%)

**Excellent (90-100%)**
- Clean, well-organized code structure
- Proper separation of concerns
- Comprehensive error handling
- Good use of Django best practices
- Scalable architecture design

**Good (70-89%)**
- Generally well-structured code
- Basic error handling
- Follows most Django conventions
- Reasonable architecture decisions
- Some code documentation

**Satisfactory (50-69%)**
- Functional but not well-organized code
- Limited error handling
- Basic Django usage
- Some architectural issues
- Minimal documentation

**Needs Improvement (0-49%)**
- Poor code organization
- No error handling
- Incorrect Django usage
- Major architectural flaws
- No documentation

### Performance & Optimization (20%)

**Excellent (90-100%)**
- Significant performance improvements demonstrated
- Optimal cache hit rates achieved
- Efficient query optimization
- Proper resource usage monitoring
- Load testing implementation

**Good (70-89%)**
- Noticeable performance improvements
- Good cache utilization
- Some query optimization
- Basic resource monitoring
- Performance testing attempts

**Satisfactory (50-69%)**
- Some performance improvements
- Basic caching working
- Limited optimization
- Minimal monitoring
- Simple performance tests

**Needs Improvement (0-49%)**
- No performance improvements
- Caching not working properly
- No optimization efforts
- No monitoring
- No performance testing

### User Experience & Interface (15%)

**Excellent (90-100%)**
- Intuitive cache management dashboard
- Real-time performance metrics display
- Clear visualization of cache statistics
- Responsive and user-friendly interface
- Comprehensive monitoring tools

**Good (70-89%)**
- Functional dashboard interface
- Basic performance metrics display
- Clear cache management options
- Decent user experience
- Some visualization elements

**Satisfactory (50-69%)**
- Basic interface for cache management
- Limited metrics display
- Functional but not polished
- Minimal user experience considerations
- Simple monitoring interface

**Needs Improvement (0-49%)**
- Poor or missing interface
- No metrics visualization
- Difficult to use
- No user experience considerations
- Non-functional monitoring

## Bonus Points

- **Advanced Redis Features** (+10%): Implementing Redis clustering, pub/sub, or advanced data structures
- **CDN Integration** (+8%): Setting up CDN for static assets with cache headers
- **Database Connection Pooling** (+6%): Optimizing database connections and pooling
- **Async Task Monitoring** (+5%): Monitoring Celery task performance
- **Performance Regression Detection** (+5%): Automated detection of performance degradation
- **Custom Cache Backends** (+4%): Implementing custom cache backends or strategies

## Common Pitfalls to Avoid

1. **Over-caching**: Caching data that changes frequently or is rarely accessed
2. **Cache Stampede**: Multiple processes regenerating the same cache simultaneously
3. **Memory Leaks**: Not properly managing cache size and expiration
4. **Inconsistent Data**: Not invalidating cache when underlying data changes
5. **Poor Cache Keys**: Using non-unique or predictable cache keys
6. **No Monitoring**: Implementing caching without monitoring its effectiveness
7. **Blocking Operations**: Using synchronous operations for cache warming
8. **Security Issues**: Exposing sensitive data through cache or monitoring interfaces

## Additional Resources

- [Django Caching Framework Documentation](https://docs.djangoproject.com/en/stable/topics/cache/)
- [Redis Documentation](https://redis.io/documentation)
- [Django Debug Toolbar](https://django-debug-toolbar.readthedocs.io/)
- [Silk Profiling Tool](https://github.com/jazzband/django-silk)
- [Performance Testing with Locust](https://locust.io/)
- [Django Performance Best Practices](https://docs.djangoproject.com/en/stable/topics/performance/)

## Time Management Suggestions

- **Setup & Planning** (30 minutes): Environment setup, requirements analysis
- **Core Caching Implementation** (90 minutes): Database, template, and API caching
- **Performance Monitoring** (60 minutes): Metrics collection and middleware
- **Dashboard Development** (45 minutes): Cache management interface
- **Testing & Optimization** (30 minutes): Performance testing and fine-tuning
- **Documentation** (15 minutes): Code comments and usage instructions

Remember to prioritize core functionality first, then add advanced features if time permits. Focus on demonstrating a solid understanding of caching principles and performance optimization strategies.
