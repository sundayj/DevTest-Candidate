# Task 4: Comprehensive Test Suite Implementation

**Time Allocation**: 2-3 hours  
**Difficulty Level**: Mid-Level  
**Focus Areas**: Testing, Quality Assurance, Test-Driven Development

## Overview

Write a comprehensive test suite for the DevTest book catalog system, focusing on unit tests, integration tests, and functional tests. This task evaluates your testing methodology, understanding of Django's testing framework, and ability to ensure code quality through proper test coverage.

## Project Setup

Follow the [Running the Project guide](../setup/running-project.md) to start the application with DevContainer, Docker Compose, or GitHub Codespaces.

## Task Requirements

### Core Testing Requirements (Required)

1. **Model Tests**
   - Test all model methods, especially `AuthorQuerySet` custom methods
   - Test model relationships and constraints
   - Test model validation and edge cases
   - Test cascade deletions and data integrity

2. **View Tests**
   - Test all view functions and class-based views
   - Test authentication and permission requirements
   - Test form handling and validation
   - Test error handling and edge cases

3. **API Tests** (if API exists)
   - Test all API endpoints
   - Test authentication and permissions
   - Test serialization and validation
   - Test error responses and status codes

4. **Integration Tests**
   - Test complete user workflows
   - Test database interactions
   - Test form submissions and redirects
   - Test template rendering

### Advanced Testing Features (Optional)

- Performance testing
- Load testing with locust
- Browser testing with Selenium
- API testing with pytest-django
- Mock external services
- Test fixtures and factories
- Code coverage reporting

## Implementation Guidelines

### 1. Test Structure and Organization

```
tests/
├── __init__.py
├── test_models.py
├── test_views.py
├── test_forms.py
├── test_api.py
├── test_utils.py
├── test_integration.py
├── fixtures/
│   ├── __init__.py
│   ├── authors.json
│   └── books.json
└── factories.py
```

### 2. Model Tests Enhancement

Extend the existing model tests:

```python
# tests/test_models.py
import pytest
from decimal import Decimal
from django.db import IntegrityError
from django.core.exceptions import ValidationError
from model_bakery import baker
from faker import Faker

from devtest.app.models import Author, Genre, Book, Review

fake = Faker()

@pytest.mark.django_db
class TestAuthorQuerySet:
    """Test custom AuthorQuerySet methods."""
    
    def test_with_average_rating_no_reviews(self):
        """Test with_average_rating when author has no reviews."""
        author = baker.make(Author)
        book = baker.make(Book, author=author)
        
        authors = Author.objects.with_average_rating()
        author_result = authors.get(id=author.id)
        
        assert author_result.avg_rating is None
        assert author_result.book_count == 1
        assert author_result.review_count == 0

    def test_with_average_rating_multiple_books(self):
        """Test with_average_rating with multiple books and reviews."""
        author = baker.make(Author)
        book1 = baker.make(Book, author=author)
        book2 = baker.make(Book, author=author)
        
        # Create reviews
        baker.make(Review, book=book1, rating=5)
        baker.make(Review, book=book1, rating=4)
        baker.make(Review, book=book2, rating=3)
        
        authors = Author.objects.with_average_rating()
        author_result = authors.get(id=author.id)
        
        assert author_result.avg_rating == Decimal('4.0')
        assert author_result.book_count == 2
        assert author_result.review_count == 3

    def test_top_authors_ordering(self):
        """Test that top_authors returns correctly ordered results."""
        # Create authors with different ratings
        author1 = baker.make(Author, name="High Rated Author")
        author2 = baker.make(Author, name="Medium Rated Author")
        author3 = baker.make(Author, name="Low Rated Author")
        
        book1 = baker.make(Book, author=author1)
        book2 = baker.make(Book, author=author2)
        book3 = baker.make(Book, author=author3)
        
        baker.make(Review, book=book1, rating=5)
        baker.make(Review, book=book2, rating=3)
        baker.make(Review, book=book3, rating=1)
        
        top_authors = Author.objects.top_authors(limit=3)
        
        assert len(top_authors) == 3
        assert top_authors[0].name == "High Rated Author"
        assert top_authors[1].name == "Medium Rated Author"
        assert top_authors[2].name == "Low Rated Author"

    def test_top_authors_limit(self):
        """Test that top_authors respects the limit parameter."""
        # Create 5 authors
        for i in range(5):
            author = baker.make(Author)
            book = baker.make(Book, author=author)
            baker.make(Review, book=book, rating=5)
        
        top_authors = Author.objects.top_authors(limit=3)
        assert len(top_authors) == 3

@pytest.mark.django_db
class TestBookModel:
    """Enhanced Book model tests."""
    
    def test_book_str_representation(self):
        """Test book string representation."""
        book = baker.make(Book, title="Test Book")
        assert str(book) == "Test Book"
    
    def test_book_author_required(self):
        """Test that book requires an author."""
        with pytest.raises(IntegrityError):
            Book.objects.create(title="Test Book")
    
    def test_book_genres_many_to_many(self):
        """Test book genres many-to-many relationship."""
        book = baker.make(Book)
        genre1 = baker.make(Genre, name="Fiction")
        genre2 = baker.make(Genre, name="Mystery")
        
        book.genres.add(genre1, genre2)
        
        assert book.genres.count() == 2
        assert genre1 in book.genres.all()
        assert genre2 in book.genres.all()

@pytest.mark.django_db
class TestReviewModel:
    """Enhanced Review model tests."""
    
    def test_review_rating_bounds(self):
        """Test review rating validation bounds."""
        book = baker.make(Book)
        
        # Valid ratings
        for rating in [1, 2, 3, 4, 5]:
            review = baker.make(Review, book=book, rating=rating)
            assert review.rating == rating
    
    def test_review_comment_optional(self):
        """Test that review comment is optional."""
        book = baker.make(Book)
        review = baker.make(Review, book=book, rating=5, comment="")
        assert review.comment == ""
    
    def test_review_created_at_auto_set(self):
        """Test that created_at is automatically set."""
        book = baker.make(Book)
        review = baker.make(Review, book=book, rating=5)
        assert review.created_at is not None
```

### 3. View Tests

```python
# tests/test_views.py
import pytest
from django.test import TestCase, Client
from django.urls import reverse
from django.contrib.auth.models import User
from model_bakery import baker

from devtest.app.models import Author, Book, Genre, Review

@pytest.mark.django_db
class TestBookViews:
    """Test book-related views."""
    
    def setup_method(self):
        """Set up test data."""
        self.client = Client()
        self.user = baker.make(User)
        self.author = baker.make(Author, name="Test Author")
        self.book = baker.make(Book, title="Test Book", author=self.author)
    
    def test_book_list_view(self):
        """Test book list view."""
        url = reverse('book_list')  # Adjust URL name as needed
        response = self.client.get(url)
        
        assert response.status_code == 200
        assert 'books' in response.context
        assert self.book.title in response.content.decode()
    
    def test_book_detail_view(self):
        """Test book detail view."""
        url = reverse('book_detail', kwargs={'pk': self.book.pk})
        response = self.client.get(url)
        
        assert response.status_code == 200
        assert response.context['book'] == self.book
    
    def test_book_detail_view_not_found(self):
        """Test book detail view with non-existent book."""
        url = reverse('book_detail', kwargs={'pk': 9999})
        response = self.client.get(url)
        
        assert response.status_code == 404

@pytest.mark.django_db
class TestReviewViews:
    """Test review-related views."""
    
    def setup_method(self):
        """Set up test data."""
        self.client = Client()
        self.user = baker.make(User)
        self.book = baker.make(Book)
    
    def test_add_review_requires_login(self):
        """Test that adding review requires authentication."""
        url = reverse('add_review', kwargs={'book_id': self.book.pk})
        response = self.client.post(url, {
            'rating': 5,
            'comment': 'Great book!'
        })
        
        # Should redirect to login
        assert response.status_code == 302
        assert '/login/' in response.url
    
    def test_add_review_authenticated(self):
        """Test adding review when authenticated."""
        self.client.force_login(self.user)
        url = reverse('add_review', kwargs={'book_id': self.book.pk})
        
        response = self.client.post(url, {
            'rating': 5,
            'comment': 'Great book!'
        })
        
        assert response.status_code == 302  # Redirect after success
        assert Review.objects.filter(book=self.book, rating=5).exists()
    
    def test_add_review_invalid_data(self):
        """Test adding review with invalid data."""
        self.client.force_login(self.user)
        url = reverse('add_review', kwargs={'book_id': self.book.pk})
        
        response = self.client.post(url, {
            'rating': 6,  # Invalid rating
            'comment': 'Great book!'
        })
        
        assert response.status_code == 200  # Form redisplayed
        assert not Review.objects.filter(book=self.book).exists()
```

### 4. Form Tests

```python
# tests/test_forms.py
import pytest
from django.test import TestCase
from model_bakery import baker

from devtest.app.forms import ReviewForm  # Adjust import as needed
from devtest.app.models import Book

@pytest.mark.django_db
class TestReviewForm:
    """Test review form validation."""
    
    def setup_method(self):
        """Set up test data."""
        self.book = baker.make(Book)
    
    def test_valid_review_form(self):
        """Test valid review form submission."""
        form_data = {
            'rating': 5,
            'comment': 'Excellent book!'
        }
        form = ReviewForm(data=form_data)
        
        assert form.is_valid()
        review = form.save(commit=False)
        review.book = self.book
        review.save()
        
        assert review.rating == 5
        assert review.comment == 'Excellent book!'
    
    def test_invalid_rating(self):
        """Test form with invalid rating."""
        form_data = {
            'rating': 6,  # Invalid
            'comment': 'Good book'
        }
        form = ReviewForm(data=form_data)
        
        assert not form.is_valid()
        assert 'rating' in form.errors
    
    def test_missing_rating(self):
        """Test form with missing rating."""
        form_data = {
            'comment': 'Good book'
        }
        form = ReviewForm(data=form_data)
        
        assert not form.is_valid()
        assert 'rating' in form.errors
    
    def test_empty_comment_allowed(self):
        """Test that empty comment is allowed."""
        form_data = {
            'rating': 4,
            'comment': ''
        }
        form = ReviewForm(data=form_data)
        
        assert form.is_valid()
```

### 5. Integration Tests

```python
# tests/test_integration.py
import pytest
from django.test import TestCase, Client
from django.urls import reverse
from django.contrib.auth.models import User
from model_bakery import baker

from devtest.app.models import Author, Book, Review

@pytest.mark.django_db
class TestBookReviewWorkflow:
    """Test complete book review workflow."""
    
    def setup_method(self):
        """Set up test data."""
        self.client = Client()
        self.user = baker.make(User, username='testuser')
        self.author = baker.make(Author, name="Test Author")
        self.book = baker.make(Book, title="Test Book", author=self.author)
    
    def test_complete_review_workflow(self):
        """Test complete workflow from book list to review submission."""
        # 1. Visit book list
        response = self.client.get(reverse('book_list'))
        assert response.status_code == 200
        
        # 2. Click on book detail
        response = self.client.get(reverse('book_detail', kwargs={'pk': self.book.pk}))
        assert response.status_code == 200
        assert self.book.title in response.content.decode()
        
        # 3. Try to add review without login (should redirect)
        response = self.client.post(reverse('add_review', kwargs={'book_id': self.book.pk}), {
            'rating': 5,
            'comment': 'Great book!'
        })
        assert response.status_code == 302
        
        # 4. Login and add review
        self.client.force_login(self.user)
        response = self.client.post(reverse('add_review', kwargs={'book_id': self.book.pk}), {
            'rating': 5,
            'comment': 'Great book!'
        })
        
        # 5. Verify review was created
        assert Review.objects.filter(book=self.book, rating=5).exists()
        review = Review.objects.get(book=self.book, rating=5)
        assert review.comment == 'Great book!'
        
        # 6. Verify review appears on book detail page
        response = self.client.get(reverse('book_detail', kwargs={'pk': self.book.pk}))
        assert 'Great book!' in response.content.decode()

@pytest.mark.django_db
class TestAuthorStatistics:
    """Test author statistics integration."""
    
    def test_author_rating_calculation(self):
        """Test that author ratings are calculated correctly across multiple books."""
        author = baker.make(Author, name="Test Author")
        
        # Create books with different ratings
        book1 = baker.make(Book, title="Book 1", author=author)
        book2 = baker.make(Book, title="Book 2", author=author)
        
        # Add reviews
        baker.make(Review, book=book1, rating=5)
        baker.make(Review, book=book1, rating=4)
        baker.make(Review, book=book2, rating=3)
        baker.make(Review, book=book2, rating=2)
        
        # Test with_average_rating method
        authors_with_ratings = Author.objects.with_average_rating()
        author_result = authors_with_ratings.get(id=author.id)
        
        expected_avg = (5 + 4 + 3 + 2) / 4  # 3.5
        assert float(author_result.avg_rating) == expected_avg
        assert author_result.book_count == 2
        assert author_result.review_count == 4
        
        # Test top_authors method
        top_authors = Author.objects.top_authors(limit=1)
        assert len(top_authors) == 1
        assert top_authors[0].id == author.id
```

### 6. Test Fixtures and Factories

```python
# tests/factories.py
import factory
from factory.django import DjangoModelFactory
from faker import Faker

from devtest.app.models import Author, Book, Genre, Review

fake = Faker()

class AuthorFactory(DjangoModelFactory):
    class Meta:
        model = Author
    
    name = factory.LazyFunction(lambda: fake.name())

class GenreFactory(DjangoModelFactory):
    class Meta:
        model = Genre
    
    name = factory.LazyFunction(lambda: fake.word())

class BookFactory(DjangoModelFactory):
    class Meta:
        model = Book
    
    title = factory.LazyFunction(lambda: fake.sentence(nb_words=3))
    author = factory.SubFactory(AuthorFactory)
    
    @factory.post_generation
    def genres(self, create, extracted, **kwargs):
        if not create:
            return
        
        if extracted:
            for genre in extracted:
                self.genres.add(genre)
        else:
            # Add random genres
            genre1 = GenreFactory()
            genre2 = GenreFactory()
            self.genres.add(genre1, genre2)

class ReviewFactory(DjangoModelFactory):
    class Meta:
        model = Review
    
    book = factory.SubFactory(BookFactory)
    rating = factory.LazyFunction(lambda: fake.random_int(min=1, max=5))
    comment = factory.LazyFunction(lambda: fake.text(max_nb_chars=200))
```

### 7. Performance Tests

```python
# tests/test_performance.py
import pytest
import time
from django.test import TestCase
from django.test.utils import override_settings
from model_bakery import baker

from devtest.app.models import Author, Book, Review

@pytest.mark.django_db
class TestQueryPerformance:
    """Test database query performance."""
    
    def test_top_authors_query_performance(self):
        """Test that top_authors query performs well with large dataset."""
        # Create test data
        authors = baker.make(Author, _quantity=100)
        for author in authors:
            books = baker.make(Book, author=author, _quantity=5)
            for book in books:
                baker.make(Review, book=book, _quantity=10)
        
        # Measure query performance
        start_time = time.time()
        top_authors = list(Author.objects.top_authors(limit=10))
        end_time = time.time()
        
        query_time = end_time - start_time
        
        # Should complete within reasonable time (adjust threshold as needed)
        assert query_time < 1.0  # 1 second
        assert len(top_authors) == 10
    
    def test_with_average_rating_query_count(self):
        """Test that with_average_rating doesn't cause N+1 queries."""
        # Create test data
        authors = baker.make(Author, _quantity=10)
        for author in authors:
            book = baker.make(Book, author=author)
            baker.make(Review, book=book, _quantity=5)
        
        with self.assertNumQueries(1):  # Should be a single query
            list(Author.objects.with_average_rating())
```

## Evaluation Criteria

### Test Coverage (30%)
- Comprehensive model testing
- View and form testing
- Integration test coverage
- Edge case handling

### Test Quality (25%)
- Clear test names and documentation
- Proper test isolation
- Appropriate assertions
- Test data management

### Testing Best Practices (20%)
- DRY principles in tests
- Proper use of fixtures/factories
- Test organization and structure
- Performance considerations

### Code Quality (15%)
- Clean, readable test code
- Proper error handling
- Maintainable test suite
- Documentation

### Advanced Features (10%)
- Performance testing
- Integration testing
- Mock usage
- Custom test utilities

## Testing Commands

```bash
# Run all tests
python manage.py test

# Run specific test file
python manage.py test tests.test_models

# Run with coverage
coverage run --source='.' manage.py test
coverage report
coverage html

# Run with pytest (if configured)
pytest
pytest tests/test_models.py
pytest -v --tb=short
pytest --cov=devtest.app
```

## Submission Guidelines

### What to Submit
1. Complete test suite files
2. Test fixtures and factories
3. Coverage report
4. Documentation of testing approach
5. Any custom test utilities

### Testing Checklist
- [ ] All models have comprehensive tests
- [ ] All views are tested
- [ ] Forms are validated properly
- [ ] Integration tests cover main workflows
- [ ] Edge cases are handled
- [ ] Performance tests are included
- [ ] Test coverage is above 90%
- [ ] All tests pass consistently

## Helpful Resources

- **Django Testing**: https://docs.djangoproject.com/en/stable/topics/testing/
- **pytest-django**: https://pytest-django.readthedocs.io/
- **Factory Boy**: https://factoryboy.readthedocs.io/
- **Coverage.py**: https://coverage.readthedocs.io/

## Time Management Tips

- **Hour 1**: Enhance model tests and create factories
- **Hour 2**: Write view and form tests
- **Hour 3**: Add integration tests and performance tests

## Common Pitfalls to Avoid

- Not testing edge cases
- Tests that depend on each other
- Not using proper test isolation
- Ignoring performance implications
- Not testing error conditions
- Hardcoding test data
- Not cleaning up test data properly

Good luck building your comprehensive test suite! Focus on quality, coverage, and maintainability.
