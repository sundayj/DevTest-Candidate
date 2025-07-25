import pytest
from faker import Faker
from model_bakery import baker

from devtest.app.models import Author, Genre, Book, Review


fake = Faker()


@pytest.fixture
def author():
    """Create a test author."""
    return baker.make(Author, name=fake.name())


@pytest.fixture
def genre():
    """Create a test genre."""
    return baker.make(Genre, name=fake.word())


@pytest.fixture
def book(author, genre):
    """Create a test book with author and genre."""
    book = baker.make(Book, title=fake.sentence(nb_words=3), author=author)
    book.genres.add(genre)
    return book


@pytest.fixture
def review(book):
    """Create a test review for a book."""
    return baker.make(
        Review,
        book=book,
        rating=fake.random_int(min=1, max=5),
        comment=fake.text(max_nb_chars=200),
    )


@pytest.fixture
def multiple_authors():
    """Create multiple authors for testing."""
    return baker.make(Author, _quantity=5)


@pytest.fixture
def multiple_books_with_reviews(multiple_authors):
    """Create multiple books with reviews for testing aggregations."""
    books = []
    for author in multiple_authors:
        book = baker.make(Book, author=author, title=fake.sentence(nb_words=3))
        # Create 2-5 reviews per book
        review_count = fake.random_int(min=2, max=5)
        baker.make(
            Review,
            book=book,
            rating=fake.random_int(min=1, max=5),
            comment=fake.text(max_nb_chars=200),
            _quantity=review_count,
        )
        books.append(book)
    return books
