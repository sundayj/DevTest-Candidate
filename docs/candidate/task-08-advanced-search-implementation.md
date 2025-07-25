# Task 8: Advanced Search Implementation

**Time Allocation**: 2-3 hours  
**Difficulty Level**: Mid to Senior Level  
**Focus Areas**: Search Algorithms, Full-Text Search, User Experience

## Overview

Implement a sophisticated search system for the DevTest book catalog that can handle full-text search across book titles, author names, and review comments. This task evaluates your understanding of search algorithms, database optimization for search, and ability to create user-friendly search experiences.

## Project Setup

Follow the [Running the Project guide](../setup/running-project.md) to start the application with DevContainer, Docker Compose, or GitHub Codespaces.

## Task Requirements

### Core Search Features (Required)

1. **Multi-Field Search**
   - Search across book titles, author names, and descriptions
   - Weighted search results (title matches rank higher)
   - Fuzzy matching for typos and partial matches
   - Case-insensitive search

2. **Advanced Search Options**
   - Filter by genre, rating range, publication date
   - Sort by relevance, rating, date, popularity
   - Search within specific fields
   - Boolean search operators (AND, OR, NOT)

3. **Search Performance**
   - Fast search response times (< 200ms)
   - Efficient database queries
   - Search result pagination
   - Search result caching

4. **User Experience**
   - Auto-complete/suggestions
   - Search result highlighting
   - "Did you mean?" suggestions
   - Search history and saved searches

### Advanced Features (Optional)

- Elasticsearch integration
- Faceted search
- Search analytics
- Machine learning-based relevance
- Voice search support
- Search result personalization

## Implementation Guidelines

### 1. Database Search Implementation

#### PostgreSQL Full-Text Search
```python
# models.py - Add search capabilities
from django.contrib.postgres.search import SearchVector, SearchQuery, SearchRank
from django.contrib.postgres.indexes import GinIndex
from django.db import models

class BookSearchManager(models.Manager):
    """Custom manager for book search functionality."""
    
    def search(self, query, filters=None):
        """Perform full-text search on books."""
        if not query:
            return self.none()
        
        # Create search vector combining multiple fields
        search_vector = (
            SearchVector('title', weight='A') +
            SearchVector('author__name', weight='B') +
            SearchVector('description', weight='C')
        )
        
        search_query = SearchQuery(query)
        
        queryset = self.annotate(
            search=search_vector,
            rank=SearchRank(search_vector, search_query)
        ).filter(
            search=search_query
        ).order_by('-rank', '-created_at')
        
        # Apply additional filters
        if filters:
            queryset = self._apply_filters(queryset, filters)
        
        return queryset
    
    def _apply_filters(self, queryset, filters):
        """Apply additional search filters."""
        if filters.get('genre'):
            queryset = queryset.filter(genres__in=filters['genre'])
        
        if filters.get('min_rating'):
            queryset = queryset.annotate(
                avg_rating=Avg('review__rating')
            ).filter(avg_rating__gte=filters['min_rating'])
        
        if filters.get('max_rating'):
            if not hasattr(queryset, 'avg_rating'):
                queryset = queryset.annotate(avg_rating=Avg('review__rating'))
            queryset = queryset.filter(avg_rating__lte=filters['max_rating'])
        
        if filters.get('author'):
            queryset = queryset.filter(author__name__icontains=filters['author'])
        
        return queryset

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.ForeignKey(Author, on_delete=models.CASCADE)
    description = models.TextField(blank=True)
    genres = models.ManyToManyField(Genre, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    objects = models.Manager()
    search_objects = BookSearchManager()
    
    class Meta:
        indexes = [
            GinIndex(fields=['title']),
            GinIndex(fields=['description']),
            models.Index(fields=['title', 'author']),
        ]
```

#### Search Vector Updates
```python
# signals.py - Update search vectors when data changes
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.contrib.postgres.search import SearchVector

@receiver(post_save, sender=Book)
def update_book_search_vector(sender, instance, **kwargs):
    """Update search vector when book is saved."""
    Book.objects.filter(pk=instance.pk).update(
        search_vector=(
            SearchVector('title', weight='A') +
            SearchVector('author__name', weight='B') +
            SearchVector('description', weight='C')
        )
    )

@receiver(post_save, sender=Author)
def update_author_books_search_vector(sender, instance, **kwargs):
    """Update search vectors for all books by this author."""
    Book.objects.filter(author=instance).update(
        search_vector=(
            SearchVector('title', weight='A') +
            SearchVector('author__name', weight='B') +
            SearchVector('description', weight='C')
        )
    )
```

### 2. Advanced Search Implementation

#### Search Service Class
```python
# services/search_service.py
import re
from typing import List, Dict, Any
from django.db.models import Q, Count, Avg
from django.contrib.postgres.search import SearchQuery, SearchRank, SearchVector
from difflib import SequenceMatcher

class AdvancedSearchService:
    """Advanced search service with multiple search strategies."""
    
    def __init__(self):
        self.min_similarity = 0.6
        self.max_suggestions = 5
    
    def search(self, query: str, filters: Dict[str, Any] = None, 
               search_type: str = 'full_text') -> Dict[str, Any]:
        """Main search method with multiple search strategies."""
        
        if not query or not query.strip():
            return self._empty_result()
        
        query = query.strip()
        filters = filters or {}
        
        # Choose search strategy
        if search_type == 'full_text':
            results = self._full_text_search(query, filters)
        elif search_type == 'fuzzy':
            results = self._fuzzy_search(query, filters)
        elif search_type == 'exact':
            results = self._exact_search(query, filters)
        else:
            results = self._combined_search(query, filters)
        
        # Add search metadata
        search_result = {
            'results': results,
            'query': query,
            'total_count': results.count() if hasattr(results, 'count') else len(results),
            'suggestions': self._get_suggestions(query) if results.count() == 0 else [],
            'filters_applied': filters,
        }
        
        return search_result
    
    def _full_text_search(self, query: str, filters: Dict[str, Any]):
        """PostgreSQL full-text search implementation."""
        search_vector = (
            SearchVector('title', weight='A') +
            SearchVector('author__name', weight='B') +
            SearchVector('description', weight='C')
        )
        
        search_query = SearchQuery(query)
        
        queryset = Book.objects.annotate(
            search=search_vector,
            rank=SearchRank(search_vector, search_query)
        ).filter(search=search_query)
        
        return self._apply_filters_and_sort(queryset, filters)
    
    def _fuzzy_search(self, query: str, filters: Dict[str, Any]):
        """Fuzzy search for handling typos and partial matches."""
        # Use trigram similarity for fuzzy matching
        from django.contrib.postgres.search import TrigramSimilarity
        
        queryset = Book.objects.annotate(
            title_similarity=TrigramSimilarity('title', query),
            author_similarity=TrigramSimilarity('author__name', query),
            description_similarity=TrigramSimilarity('description', query),
        ).annotate(
            # Combined similarity score
            similarity=(
                models.F('title_similarity') * 3 +
                models.F('author_similarity') * 2 +
                models.F('description_similarity')
            ) / 6
        ).filter(
            similarity__gt=self.min_similarity
        ).order_by('-similarity')
        
        return self._apply_filters_and_sort(queryset, filters, sort_by='similarity')
    
    def _exact_search(self, query: str, filters: Dict[str, Any]):
        """Exact match search."""
        q_objects = Q()
        
        # Search in different fields
        q_objects |= Q(title__icontains=query)
        q_objects |= Q(author__name__icontains=query)
        q_objects |= Q(description__icontains=query)
        
        queryset = Book.objects.filter(q_objects)
        return self._apply_filters_and_sort(queryset, filters)
    
    def _combined_search(self, query: str, filters: Dict[str, Any]):
        """Combined search using multiple strategies."""
        # Try full-text search first
        full_text_results = self._full_text_search(query, filters)
        
        if full_text_results.count() > 0:
            return full_text_results
        
        # Fall back to fuzzy search
        fuzzy_results = self._fuzzy_search(query, filters)
        
        if fuzzy_results.count() > 0:
            return fuzzy_results
        
        # Finally try exact search
        return self._exact_search(query, filters)
    
    def _apply_filters_and_sort(self, queryset, filters: Dict[str, Any], 
                               sort_by: str = 'rank'):
        """Apply filters and sorting to queryset."""
        
        # Apply genre filter
        if filters.get('genres'):
            queryset = queryset.filter(genres__in=filters['genres'])
        
        # Apply rating filter
        if filters.get('min_rating') or filters.get('max_rating'):
            queryset = queryset.annotate(avg_rating=Avg('review__rating'))
            
            if filters.get('min_rating'):
                queryset = queryset.filter(avg_rating__gte=filters['min_rating'])
            
            if filters.get('max_rating'):
                queryset = queryset.filter(avg_rating__lte=filters['max_rating'])
        
        # Apply date range filter
        if filters.get('date_from'):
            queryset = queryset.filter(created_at__gte=filters['date_from'])
        
        if filters.get('date_to'):
            queryset = queryset.filter(created_at__lte=filters['date_to'])
        
        # Apply sorting
        sort_field = filters.get('sort_by', sort_by)
        if sort_field == 'title':
            queryset = queryset.order_by('title')
        elif sort_field == 'author':
            queryset = queryset.order_by('author__name')
        elif sort_field == 'date':
            queryset = queryset.order_by('-created_at')
        elif sort_field == 'rating':
            if not hasattr(queryset.query.annotations, 'avg_rating'):
                queryset = queryset.annotate(avg_rating=Avg('review__rating'))
            queryset = queryset.order_by('-avg_rating')
        elif sort_field == 'popularity':
            queryset = queryset.annotate(
                review_count=Count('review')
            ).order_by('-review_count')
        
        return queryset.select_related('author').prefetch_related('genres')
    
    def _get_suggestions(self, query: str) -> List[str]:
        """Generate search suggestions for failed searches."""
        suggestions = []
        
        # Get all book titles and author names
        all_titles = Book.objects.values_list('title', flat=True)
        all_authors = Author.objects.values_list('name', flat=True)
        
        all_terms = list(all_titles) + list(all_authors)
        
        # Find similar terms
        for term in all_terms:
            similarity = SequenceMatcher(None, query.lower(), term.lower()).ratio()
            if 0.4 < similarity < 0.9:  # Not too similar, not too different
                suggestions.append(term)
        
        # Sort by similarity and return top suggestions
        suggestions.sort(key=lambda x: SequenceMatcher(None, query.lower(), x.lower()).ratio(), reverse=True)
        return suggestions[:self.max_suggestions]
    
    def _empty_result(self):
        """Return empty search result."""
        return {
            'results': Book.objects.none(),
            'query': '',
            'total_count': 0,
            'suggestions': [],
            'filters_applied': {},
        }

class SearchAutoComplete:
    """Auto-complete functionality for search."""
    
    @staticmethod
    def get_suggestions(query: str, limit: int = 10) -> List[Dict[str, str]]:
        """Get auto-complete suggestions."""
        if len(query) < 2:
            return []
        
        suggestions = []
        
        # Book title suggestions
        book_titles = Book.objects.filter(
            title__icontains=query
        ).values_list('title', flat=True)[:limit//2]
        
        for title in book_titles:
            suggestions.append({
                'text': title,
                'type': 'book',
                'category': 'Books'
            })
        
        # Author name suggestions
        author_names = Author.objects.filter(
            name__icontains=query
        ).values_list('name', flat=True)[:limit//2]
        
        for name in author_names:
            suggestions.append({
                'text': name,
                'type': 'author',
                'category': 'Authors'
            })
        
        return suggestions[:limit]
```

### 3. Search API Implementation

#### Search Views
```python
# views/search_views.py
from django.shortcuts import render
from django.http import JsonResponse
from django.core.paginator import Paginator
from django.views.decorators.http import require_http_methods
from django.views.decorators.cache import cache_page

from ..services.search_service import AdvancedSearchService, SearchAutoComplete

class SearchView:
    """Main search view handling."""
    
    def __init__(self):
        self.search_service = AdvancedSearchService()
    
    def search_books(self, request):
        """Main search endpoint."""
        query = request.GET.get('q', '').strip()
        page = int(request.GET.get('page', 1))
        per_page = int(request.GET.get('per_page', 20))
        
        # Build filters from request
        filters = self._build_filters(request)
        
        # Perform search
        search_result = self.search_service.search(
            query=query,
            filters=filters,
            search_type=request.GET.get('search_type', 'full_text')
        )
        
        # Paginate results
        paginator = Paginator(search_result['results'], per_page)
        page_obj = paginator.get_page(page)
        
        context = {
            'query': query,
            'results': page_obj,
            'total_count': search_result['total_count'],
            'suggestions': search_result['suggestions'],
            'filters': filters,
            'page_obj': page_obj,
        }
        
        if request.headers.get('Accept') == 'application/json':
            return self._json_response(context)
        
        return render(request, 'search/results.html', context)
    
    def _build_filters(self, request):
        """Build filters from request parameters."""
        filters = {}
        
        if request.GET.get('genres'):
            genre_ids = [int(g) for g in request.GET.getlist('genres') if g.isdigit()]
            if genre_ids:
                filters['genres'] = Genre.objects.filter(id__in=genre_ids)
        
        if request.GET.get('min_rating'):
            try:
                filters['min_rating'] = float(request.GET.get('min_rating'))
            except ValueError:
                pass
        
        if request.GET.get('max_rating'):
            try:
                filters['max_rating'] = float(request.GET.get('max_rating'))
            except ValueError:
                pass
        
        if request.GET.get('author'):
            filters['author'] = request.GET.get('author')
        
        if request.GET.get('sort_by'):
            filters['sort_by'] = request.GET.get('sort_by')
        
        return filters
    
    def _json_response(self, context):
        """Return JSON response for AJAX requests."""
        results_data = []
        for book in context['results']:
            results_data.append({
                'id': book.id,
                'title': book.title,
                'author': book.author.name,
                'genres': [g.name for g in book.genres.all()],
                'avg_rating': getattr(book, 'avg_rating', None),
                'url': f'/books/{book.id}/'
            })
        
        return JsonResponse({
            'results': results_data,
            'total_count': context['total_count'],
            'has_next': context['page_obj'].has_next(),
            'has_previous': context['page_obj'].has_previous(),
            'current_page': context['page_obj'].number,
            'total_pages': context['page_obj'].paginator.num_pages,
            'suggestions': context['suggestions'],
        })

@require_http_methods(["GET"])
@cache_page(60 * 5)  # Cache for 5 minutes
def autocomplete(request):
    """Auto-complete endpoint."""
    query = request.GET.get('q', '').strip()
    limit = int(request.GET.get('limit', 10))
    
    suggestions = SearchAutoComplete.get_suggestions(query, limit)
    
    return JsonResponse({
        'suggestions': suggestions
    })

# URL patterns
from django.urls import path

search_view = SearchView()

urlpatterns = [
    path('search/', search_view.search_books, name='search_books'),
    path('search/autocomplete/', autocomplete, name='search_autocomplete'),
]
```

### 4. Frontend Search Implementation

#### Search Form Template
```html
<!-- templates/search/search_form.html -->
<div class="search-container">
    <form id="search-form" method="get" action="{% url 'search_books' %}">
        <div class="search-input-group">
            <input type="text" 
                   id="search-input" 
                   name="q" 
                   value="{{ query }}"
                   placeholder="Search books, authors..."
                   autocomplete="off">
            <button type="submit" class="search-btn">
                <i class="fas fa-search"></i>
            </button>
        </div>
        
        <!-- Auto-complete dropdown -->
        <div id="autocomplete-dropdown" class="autocomplete-dropdown" style="display: none;">
            <ul id="autocomplete-list"></ul>
        </div>
        
        <!-- Advanced filters (collapsible) -->
        <div class="advanced-filters" id="advanced-filters" style="display: none;">
            <div class="filter-row">
                <div class="filter-group">
                    <label for="genres">Genres:</label>
                    <select name="genres" id="genres" multiple>
                        {% for genre in all_genres %}
                            <option value="{{ genre.id }}" 
                                    {% if genre.id in selected_genres %}selected{% endif %}>
                                {{ genre.name }}
                            </option>
                        {% endfor %}
                    </select>
                </div>
                
                <div class="filter-group">
                    <label for="min_rating">Min Rating:</label>
                    <select name="min_rating" id="min_rating">
                        <option value="">Any</option>
                        <option value="1" {% if min_rating == 1 %}selected{% endif %}>1+</option>
                        <option value="2" {% if min_rating == 2 %}selected{% endif %}>2+</option>
                        <option value="3" {% if min_rating == 3 %}selected{% endif %}>3+</option>
                        <option value="4" {% if min_rating == 4 %}selected{% endif %}>4+</option>
                        <option value="5" {% if min_rating == 5 %}selected{% endif %}>5</option>
                    </select>
                </div>
                
                <div class="filter-group">
                    <label for="sort_by">Sort by:</label>
                    <select name="sort_by" id="sort_by">
                        <option value="rank" {% if sort_by == 'rank' %}selected{% endif %}>Relevance</option>
                        <option value="title" {% if sort_by == 'title' %}selected{% endif %}>Title</option>
                        <option value="author" {% if sort_by == 'author' %}selected{% endif %}>Author</option>
                        <option value="rating" {% if sort_by == 'rating' %}selected{% endif %}>Rating</option>
                        <option value="date" {% if sort_by == 'date' %}selected{% endif %}>Date</option>
                    </select>
                </div>
            </div>
            
            <div class="filter-actions">
                <button type="submit" class="btn btn-primary">Apply Filters</button>
                <button type="button" id="clear-filters" class="btn btn-secondary">Clear</button>
            </div>
        </div>
        
        <button type="button" id="toggle-filters" class="toggle-filters-btn">
            Advanced Filters <i class="fas fa-chevron-down"></i>
        </button>
    </form>
</div>
```

#### Search JavaScript
```javascript
// static/js/search.js
class SearchManager {
    constructor() {
        this.searchInput = document.getElementById('search-input');
        this.searchForm = document.getElementById('search-form');
        this.autocompleteDropdown = document.getElementById('autocomplete-dropdown');
        this.autocompleteList = document.getElementById('autocomplete-list');
        this.advancedFilters = document.getElementById('advanced-filters');
        this.toggleFiltersBtn = document.getElementById('toggle-filters');
        
        this.debounceTimer = null;
        this.currentRequest = null;
        
        this.init();
    }
    
    init() {
        this.bindEvents();
        this.initializeFilters();
    }
    
    bindEvents() {
        // Search input events
        this.searchInput.addEventListener('input', (e) => {
            this.handleSearchInput(e.target.value);
        });
        
        this.searchInput.addEventListener('focus', () => {
            if (this.searchInput.value.length >= 2) {
                this.showAutocomplete();
            }
        });
        
        this.searchInput.addEventListener('blur', () => {
            // Delay hiding to allow clicking on suggestions
            setTimeout(() => this.hideAutocomplete(), 200);
        });
        
        // Form submission
        this.searchForm.addEventListener('submit', (e) => {
            this.handleFormSubmit(e);
        });
        
        // Advanced filters toggle
        this.toggleFiltersBtn.addEventListener('click', () => {
            this.toggleAdvancedFilters();
        });
        
        // Clear filters
        document.getElementById('clear-filters').addEventListener('click', () => {
            this.clearFilters();
        });
        
        // Keyboard navigation for autocomplete
        this.searchInput.addEventListener('keydown', (e) => {
            this.handleKeyNavigation(e);
        });
    }
    
    handleSearchInput(value) {
        clearTimeout(this.debounceTimer);
        
        if (value.length < 2) {
            this.hideAutocomplete();
            return;
        }
        
        this.debounceTimer = setTimeout(() => {
            this.fetchAutocomplete(value);
        }, 300);
    }
    
    async fetchAutocomplete(query) {
        if (this.currentRequest) {
            this.currentRequest.abort();
        }
        
        try {
            this.currentRequest = new AbortController();
            
            const response = await fetch(`/search/autocomplete/?q=${encodeURIComponent(query)}`, {
                signal: this.currentRequest.signal
            });
            
            if (!response.ok) throw new Error('Network response was not ok');
            
            const data = await response.json();
            this.displayAutocomplete(data.suggestions);
            
        } catch (error) {
            if (error.name !== 'AbortError') {
                console.error('Autocomplete error:', error);
            }
        }
    }
    
    displayAutocomplete(suggestions) {
        this.autocompleteList.innerHTML = '';
        
        if (suggestions.length === 0) {
            this.hideAutocomplete();
            return;
        }
        
        suggestions.forEach((suggestion, index) => {
            const li = document.createElement('li');
            li.className = 'autocomplete-item';
            li.innerHTML = `
                <div class="suggestion-text">${this.highlightMatch(suggestion.text)}</div>
                <div class="suggestion-category">${suggestion.category}</div>
            `;
            
            li.addEventListener('click', () => {
                this.selectSuggestion(suggestion.text);
            });
            
            this.autocompleteList.appendChild(li);
        });
        
        this.showAutocomplete();
    }
    
    highlightMatch(text) {
        const query = this.searchInput.value;
        const regex = new RegExp(`(${query})`, 'gi');
        return text.replace(regex, '<strong>$1</strong>');
    }
    
    selectSuggestion(text) {
        this.searchInput.value = text;
        this.hideAutocomplete();
        this.searchForm.submit();
    }
    
    showAutocomplete() {
        this.autocompleteDropdown.style.display = 'block';
    }
    
    hideAutocomplete() {
        this.autocompleteDropdown.style.display = 'none';
    }
    
    handleKeyNavigation(e) {
        const items = this.autocompleteList.querySelectorAll('.autocomplete-item');
        const currentActive = this.autocompleteList.querySelector('.active');
        
        if (e.key === 'ArrowDown') {
            e.preventDefault();
            if (currentActive) {
                currentActive.classList.remove('active');
                const next = currentActive.nextElementSibling || items[0];
                next.classList.add('active');
            } else if (items.length > 0) {
                items[0].classList.add('active');
            }
        } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            if (currentActive) {
                currentActive.classList.remove('active');
                const prev = currentActive.previousElementSibling || items[items.length - 1];
                prev.classList.add('active');
            } else if (items.length > 0) {
                items[items.length - 1].classList.add('active');
            }
        } else if (e.key === 'Enter') {
            if (currentActive) {
                e.preventDefault();
                const text = currentActive.querySelector('.suggestion-text').textContent;
                this.selectSuggestion(text);
            }
        } else if (e.key === 'Escape') {
            this.hideAutocomplete();
        }
    }
    
    toggleAdvancedFilters() {
        const isVisible = this.advancedFilters.style.display !== 'none';
        this.advancedFilters.style.display = isVisible ? 'none' : 'block';
        
        const icon = this.toggleFiltersBtn.querySelector('i');
        icon.className = isVisible ? 'fas fa-chevron-down' : 'fas fa-chevron-up';
    }
    
    clearFilters() {
        // Reset all filter inputs
        document.getElementById('genres').selectedIndex = -1;
        document.getElementById('min_rating').selectedIndex = 0;
        document.getElementById('sort_by').selectedIndex = 0;
        
        // Submit form to refresh results
        this.searchForm.submit();
    }
    
    handleFormSubmit(e) {
        // Add loading state
        const submitBtn = this.searchForm.querySelector('button[type="submit"]');
        const originalText = submitBtn.innerHTML;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Searching...';
        submitBtn.disabled = true;
        
        // Re-enable after a delay (form will redirect anyway)
        setTimeout(() => {
            submitBtn.innerHTML = originalText;
            submitBtn.disabled = false;
        }, 2000);
    }
    
    initializeFilters() {
        // Initialize any filter-specific functionality
        // e.g., multi-select dropdowns, date pickers, etc.
    }
}

// Initialize search when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new SearchManager();
});
```

### 5. Search Results Template

```html
<!-- templates/search/results.html -->
{% extends 'base.html' %}

{% block title %}Search Results{% if query %} for "{{ query }}"{% endif %}{% endblock %}

{% block content %}
<div class="search-results-container">
    <!-- Search form -->
    {% include 'search/search_form.html' %}
    
    <!-- Results summary -->
    <div class="results-summary">
        {% if query %}
            <h2>Search Results for "{{ query }}"</h2>
            <p>Found {{ total_count }} result{{ total_count|pluralize }} 
               {% if page_obj.paginator.num_pages > 1 %}
                   (Page {{ page_obj.number }} of {{ page_obj.paginator.num_pages }})
               {% endif %}
            </p>
        {% else %}
            <h2>Search Books</h2>
            <p>Enter a search term to find books, authors, or topics.</p>
        {% endif %}
    </div>
    
    <!-- Search suggestions for no results -->
    {% if suggestions %}
        <div class="search-suggestions">
            <h3>Did you mean?</h3>
            <ul>
                {% for suggestion in suggestions %}
                    <li>
                        <a href="?q={{ suggestion|urlencode }}">{{ suggestion }}</a>
                    </li>
                {% endfor %}
            </ul>
        </div>
    {% endif %}
    
    <!-- Search results -->
    {% if results %}
        <div class="search-results">
            {% for book in results %}
                <div class="search-result-item">
                    <div class="book-info">
                        <h3><a href="{% url 'book_detail' book.id %}">{{ book.title }}</a></h3>
                        <p class="author">by <a href="{% url 'author_detail' book.author.id %}">{{ book.author.name }}</a></p>
                        
                        {% if book.description %}
                            <p class="description">{{ book.description|truncatewords:30 }}</p>
                        {% endif %}
                        
                        <div class="book-meta">
                            <div class="genres">
                                {% for genre in book.genres.all %}
                                    <span class="genre-tag">{{ genre.name }}</span>
                                {% endfor %}
                            </div>
                            
                            {% if book.avg_rating %}
                                <div class="rating">
                                    <span class="stars">
                                        {% for i in "12345" %}
                                            {% if forloop.counter <= book.avg_rating %}
                                                <i class="fas fa-star"></i>
                                            {% else %}
                                                <i class="far fa-star"></i>
                                            {% endif %}
                                        {% endfor %}
                                    </span>
                                    <span class="rating-value">({{ book.avg_rating|floatformat:1 }})</span>
                                </div>
                            {% endif %}
                        </div>
                    </div>
                </div>
            {% endfor %}
        </div>
        
        <!-- Pagination -->
        {% if page_obj.paginator.num_pages > 1 %}
            <div class="pagination-container">
                <nav aria-label="Search results pagination">
                    <ul class="pagination">
                        {% if page_obj.has_previous %}
                            <li class="page-item">
                                <a class="page-link" href="?{{ request.GET.urlencode }}&page=1">First</a>
                            </li>
                            <li class="page-item">
                                <a class="page-link" href="?{{ request.GET.urlencode }}&page={{ page_obj.previous_page_number }}">Previous</a>
                            </li>
                        {% endif %}
                        
                        {% for num in page_obj.paginator.page_range %}
                            {% if page_obj.number == num %}
                                <li class="page-item active">
                                    <span class="page-link">{{ num }}</span>
                                </li>
                            {% elif num > page_obj.number|add:'-3' and num < page_obj.number|add:'3' %}
                                <li class="page-item">
                                    <a class="page-link" href="?{{ request.GET.urlencode }}&page={{ num }}">{{ num }}</a>
                                </li>
                            {% endif %}
                        {% endfor %}
                        
                        {% if page_obj.has_next %}
                            <li class="page-item">
                                <a class="page-link" href="?{{ request.GET.urlencode }}&page={{ page_obj.next_page_number }}">Next</a>
                            </li>
                            <li class="page-item">
                                <a class="page-link" href="?{{ request.GET.urlencode }}&page={{ page_obj.paginator.num_pages }}">Last</a>
                            </li>
                        {% endif %}
                    </ul>
                </nav>
            </div>
        {% endif %}
        
    {% elif query %}
        <div class="no-results">
            <h3>No results found</h3>
            <p>Try adjusting your search terms or filters.</p>
            
            <div class="search-tips">
                <h4>Search Tips:</h4>
                <ul>
                    <li>Check your spelling</li>
                    <li>Try different keywords</li>
                    <li>Use fewer words</li>
                    <li>Try searching for author names</li>
                </ul>
            </div>
        </div>
    {% endif %}
</div>
{% endblock %}
```

## Evaluation Criteria

### Search Functionality (30%)
- Accuracy of search results
- Relevance ranking
- Multi-field search capability
- Fuzzy matching implementation

### Performance (25%)
- Search response time
- Database query optimization
- Efficient indexing
- Caching implementation

### User Experience (20%)
- Auto-complete functionality
- Search result presentation
- Filter and sort options
- Mobile responsiveness

### Code Quality (15%)
- Clean, maintainable code
- Proper error handling
- Documentation
- Testing coverage

### Advanced Features (10%)
- Search suggestions
- Result highlighting
- Search analytics
- Innovative search features

## Submission Guidelines

### What to Submit
1. **Search Models**: Enhanced models with search capabilities
2. **Search Service**: Search logic and algorithms
3. **Search Views**: API endpoints and view handlers
4. **Frontend Code**: JavaScript and templates
5. **Database Migrations**: Search indexes and optimizations
6. **Documentation**: Search features and usage guide

### Performance Benchmarks
Include metrics for:
- Search response time
- Database query count
- Index usage
- Memory consumption

## Helpful Resources

- **PostgreSQL Full-Text Search**: https://www.postgresql.org/docs/current/textsearch.html
- **Django Search**: https://docs.djangoproject.com/en/stable/ref/contrib/postgres/search/
- **Elasticsearch**: https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html
- **Search UX Best Practices**: https://www.nngroup.com/articles/search-interface/

## Time Management Tips

- **Hour 1**: Implement basic search functionality and database setup
- **Hour 2**: Add advanced search features and auto-complete
- **Hour 3**: Optimize performance and enhance user experience

## Common Pitfalls to Avoid

- Not handling empty or invalid search queries
- Poor search result ranking
- Slow search performance with large datasets
- Missing search result highlighting
- Not implementing proper pagination
- Ignoring mobile search experience
- Not providing search suggestions for failed searches

Good luck implementing your advanced search system! Focus on creating a fast, accurate, and user-friendly search experience.
