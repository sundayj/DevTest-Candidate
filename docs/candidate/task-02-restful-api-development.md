# Task 2: RESTful API Development

**Time Allocation**: 2-3 hours  
**Difficulty Level**: Mid-Level  
**Focus Areas**: Backend Development, REST API Design, Django REST Framework

## Overview

Build comprehensive RESTful API endpoints for the DevTest book catalog system using Django REST Framework. This task evaluates your backend development skills, API design principles, and understanding of REST conventions.

## Project Setup

Follow the [Running the Project guide](../setup/running-project.md) to start the application with DevContainer, Docker Compose, or GitHub Codespaces.

## Task Requirements

### Core API Endpoints (Required)

1. **Books API**
   - `GET /api/books/` - List all books with pagination
   - `GET /api/books/{id}/` - Retrieve specific book details
   - `POST /api/books/` - Create new book (authenticated users)
   - `PUT /api/books/{id}/` - Update book (authenticated users)
   - `DELETE /api/books/{id}/` - Delete book (authenticated users)

2. **Authors API**
   - `GET /api/authors/` - List all authors
   - `GET /api/authors/{id}/` - Retrieve author details with books
   - `GET /api/authors/top/` - Get top authors (using existing top_authors method)
   - `POST /api/authors/` - Create new author (authenticated users)

3. **Reviews API**
   - `GET /api/books/{book_id}/reviews/` - List reviews for a book
   - `POST /api/books/{book_id}/reviews/` - Add review to book
   - `GET /api/reviews/{id}/` - Retrieve specific review
   - `PUT /api/reviews/{id}/` - Update review (review owner only)
   - `DELETE /api/reviews/{id}/` - Delete review (review owner only)

4. **Genres API**
   - `GET /api/genres/` - List all genres
   - `GET /api/genres/{id}/books/` - List books in specific genre

### Technical Requirements

- Use Django REST Framework (DRF)
- Implement proper serialization and validation
- Add basic authentication (Token or Session)
- Include comprehensive error handling
- Implement pagination for list endpoints
- Add filtering and search capabilities
- Follow REST conventions and HTTP status codes

### Authentication & Permissions

- Implement token-based authentication
- Read operations: Public access
- Write operations: Authenticated users only
- Review modifications: Review owner only
- Book/Author modifications: Staff users only

### Bonus Features (Optional)

- API versioning (v1, v2)
- Rate limiting
- API documentation with Swagger/OpenAPI
- Advanced filtering with django-filter
- Bulk operations
- File upload for book covers
- API caching with Redis

## Implementation Guidelines

### 1. Install Django REST Framework

Add to requirements or install:
```bash
pip install djangorestframework
pip install django-filter  # for filtering
pip install djangorestframework-simplejwt  # for JWT auth
```

### 2. Serializers Structure
```python
# serializers.py
from rest_framework import serializers
from .models import Author, Book, Genre, Review

class GenreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Genre
        fields = ['id', 'name']

class AuthorSerializer(serializers.ModelSerializer):
    book_count = serializers.IntegerField(read_only=True)
    avg_rating = serializers.DecimalField(max_digits=3, decimal_places=2, read_only=True)
    
    class Meta:
        model = Author
        fields = ['id', 'name', 'book_count', 'avg_rating']

class BookSerializer(serializers.ModelSerializer):
    author = AuthorSerializer(read_only=True)
    author_id = serializers.IntegerField(write_only=True)
    genres = GenreSerializer(many=True, read_only=True)
    genre_ids = serializers.ListField(child=serializers.IntegerField(), write_only=True)
    average_rating = serializers.SerializerMethodField()
    review_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Book
        fields = ['id', 'title', 'author', 'author_id', 'genres', 'genre_ids', 
                 'average_rating', 'review_count']
    
    def get_average_rating(self, obj):
        # Calculate average rating
        pass
    
    def get_review_count(self, obj):
        # Get review count
        pass

class ReviewSerializer(serializers.ModelSerializer):
    book = BookSerializer(read_only=True)
    book_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = Review
        fields = ['id', 'book', 'book_id', 'rating', 'comment', 'created_at']
    
    def validate_rating(self, value):
        if not 1 <= value <= 5:
            raise serializers.ValidationError("Rating must be between 1 and 5")
        return value
```

### 3. ViewSets Structure
```python
# views.py or viewsets.py
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from django_filters.rest_framework import DjangoFilterBackend

class BookViewSet(viewsets.ModelViewSet):
    queryset = Book.objects.select_related('author').prefetch_related('genres')
    serializer_class = BookSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['author', 'genres']
    search_fields = ['title', 'author__name']
    ordering_fields = ['title', 'created_at']
    ordering = ['title']

class AuthorViewSet(viewsets.ModelViewSet):
    queryset = Author.objects.all()
    serializer_class = AuthorSerializer
    
    @action(detail=False, methods=['get'])
    def top(self, request):
        limit = request.query_params.get('limit', 5)
        top_authors = Author.objects.top_authors(limit=int(limit))
        serializer = self.get_serializer(top_authors, many=True)
        return Response(serializer.data)
```

### 4. URL Configuration
```python
# urls.py
from rest_framework.routers import DefaultRouter
from . import viewsets

router = DefaultRouter()
router.register(r'books', viewsets.BookViewSet)
router.register(r'authors', viewsets.AuthorViewSet)
router.register(r'reviews', viewsets.ReviewViewSet)
router.register(r'genres', viewsets.GenreViewSet)

urlpatterns = [
    path('api/', include(router.urls)),
    path('api-auth/', include('rest_framework.urls')),
]
```

### 5. Authentication Setup
```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticatedOrReadOnly',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
}
```

## API Documentation Examples

### Book List Response
```json
{
    "count": 150,
    "next": "http://localhost:8001/api/books/?page=2",
    "previous": null,
    "results": [
        {
            "id": 1,
            "title": "The Great Gatsby",
            "author": {
                "id": 1,
                "name": "F. Scott Fitzgerald",
                "book_count": 3,
                "avg_rating": 4.2
            },
            "genres": [
                {"id": 1, "name": "Fiction"},
                {"id": 2, "name": "Classic"}
            ],
            "average_rating": 4.2,
            "review_count": 15
        }
    ]
}
```

### Error Response Format
```json
{
    "error": "Validation failed",
    "details": {
        "rating": ["Rating must be between 1 and 5"],
        "book_id": ["This field is required"]
    }
}
```

## Evaluation Criteria

### API Design (25%)
- RESTful conventions followed
- Proper HTTP status codes
- Consistent response formats
- Logical endpoint structure

### Serialization & Validation (25%)
- Proper field serialization
- Input validation
- Error handling
- Nested serializers usage

### Authentication & Permissions (20%)
- Secure authentication implementation
- Proper permission classes
- User-specific data access
- Security best practices

### Code Quality (15%)
- Clean, readable code
- Proper documentation
- DRY principles
- Error handling

### Performance (15%)
- Efficient database queries
- Proper use of select_related/prefetch_related
- Pagination implementation
- Query optimization

## Testing Your API

### Manual Testing with curl
```bash
# Get all books
curl -X GET http://localhost:8001/api/books/

# Create a review (requires authentication)
curl -X POST http://localhost:8001/api/books/1/reviews/ \
  -H "Authorization: Token your-token-here" \
  -H "Content-Type: application/json" \
  -d '{"rating": 5, "comment": "Great book!"}'

# Search books
curl -X GET "http://localhost:8001/api/books/?search=gatsby"

# Filter by author
curl -X GET "http://localhost:8001/api/books/?author=1"
```

### API Testing Tools
- Use Postman or Insomnia for interactive testing
- Test all CRUD operations
- Verify authentication and permissions
- Test error scenarios
- Check pagination and filtering

### Running Postman Collections with Newman
With Node.js and the Newman CLI installed in the container, you can automate Postman collection tests.

**Inside the DevContainer**
```bash
devcontainer exec --workspace-folder . newman run path/to/collection.json
```

**With Docker Compose**
```bash
docker-compose run --rm web newman run path/to/collection.json
```

## Submission Guidelines

### What to Submit
1. All serializer classes
2. ViewSet implementations
3. URL configuration
4. Authentication setup
5. Any custom permissions or filters
6. API documentation (README or comments)

### Code Organization
```
api/
├── serializers.py
├── viewsets.py
├── permissions.py
├── filters.py
└── urls.py
```

### Testing Checklist
- [ ] All endpoints return correct data
- [ ] Authentication works properly
- [ ] Permissions are enforced
- [ ] Validation catches invalid data
- [ ] Error responses are properly formatted
- [ ] Pagination works correctly
- [ ] Search and filtering function
- [ ] Performance is acceptable

## Helpful Resources

- **Django REST Framework**: https://www.django-rest-framework.org/
- **API Design Best Practices**: https://restfulapi.net/
- **HTTP Status Codes**: https://httpstatuses.com/
- **Token Authentication**: https://www.django-rest-framework.org/api-guide/authentication/

## Time Management Tips

- **Hour 1**: Set up DRF, create basic serializers and viewsets
- **Hour 2**: Implement authentication, permissions, and validation
- **Hour 3**: Add filtering, search, optimize queries, test thoroughly

## Common Pitfalls to Avoid

- Not handling authentication properly
- Missing input validation
- Inefficient database queries (N+1 problems)
- Inconsistent error response formats
- Not following REST conventions
- Missing proper HTTP status codes
- Not implementing proper permissions

Good luck building your API! Focus on creating a well-designed, secure, and efficient REST API.
