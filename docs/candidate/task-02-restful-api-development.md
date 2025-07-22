# Task 2: RESTful API Development

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
- **Write comprehensive tests** for all API endpoints, authentication, and permissions

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

## Submission Guidelines

### What to Submit
1. All API endpoint implementations (views.py or viewsets)
2. Serializers for all models
3. Updated urls.py with API routing
4. Authentication and permission classes
5. Any custom middleware or utilities
6. API documentation or usage examples
7. **Comprehensive test suite** covering all endpoints, authentication, and edge cases

### Code Organization
- Follow Django REST Framework best practices
- Use meaningful commit messages
- Include comprehensive docstrings
- Ensure proper error handling

### Testing Your Solution
Before submission, verify:
- All endpoints return correct HTTP status codes
- Authentication and permissions work as specified
- Pagination works for list endpoints
- API handles invalid data gracefully
- All CRUD operations function correctly

## Helpful Resources

- **Django REST Framework**: https://www.django-rest-framework.org/
- **DRF Authentication**: https://www.django-rest-framework.org/api-guide/authentication/
- **DRF Permissions**: https://www.django-rest-framework.org/api-guide/permissions/
- **DRF Serializers**: https://www.django-rest-framework.org/api-guide/serializers/

Good luck with your implementation! Focus on creating a well-structured, secure, and maintainable API.
