import pytest
from faker import Faker
from model_bakery import baker

from devtest.app.models import Author, Genre, Book, Review


fake = Faker()


@pytest.mark.django_db
class TestModelIntegration:
    """Integration tests for model relationships and complex queries."""

    def test_complete_book_ecosystem(self):
        """Test creating a complete book ecosystem with all relationships."""
        # Create author
        author = baker.make(Author, name=fake.name())

        # Create genres
        genres = baker.make(Genre, _quantity=3)

        # Create book with author and genres
        book = baker.make(Book, title=fake.sentence(nb_words=4), author=author)
        book.genres.set(genres)

        # Create reviews
        reviews = baker.make(
            Review,
            book=book,
            rating=fake.random_int(min=1, max=5),
            comment=fake.text(max_nb_chars=200),
            _quantity=5,
        )

        # Verify relationships
        assert book.author == author
        assert book.genres.count() == 3
        assert book.review_set.count() == 5
        assert author.book_set.count() == 1

        # Test author aggregations
        author_with_stats = Author.objects.with_average_rating().get(id=author.id)
        assert author_with_stats.book_count == 1
        assert author_with_stats.review_count == 5
        assert author_with_stats.avg_rating is not None

    def test_multiple_books_per_author(self):
        """Test an author with multiple books and reviews."""
        author = baker.make(Author, name=fake.name())

        # Create 3 books for the author
        books = []
        for _ in range(3):
            book = baker.make(Book, author=author,
                              title=fake.sentence(nb_words=3))
            # Add 2-4 reviews per book
            baker.make(
                Review,
                book=book,
                rating=fake.random_int(min=1, max=5),
                _quantity=fake.random_int(min=2, max=4),
            )
            books.append(book)

        # Test aggregations
        author_with_stats = Author.objects.with_average_rating().get(id=author.id)
        assert author_with_stats.book_count == 3
        assert author_with_stats.review_count >= 6  # At least 2 reviews per book
        assert author_with_stats.avg_rating is not None

    @pytest.mark.slow
    def test_performance_with_many_records(self):
        """Test performance with a larger dataset."""
        # Create 10 authors
        authors = baker.make(Author, _quantity=10)

        # Create 50 books (5 per author on average)
        books = []
        for author in authors:
            author_books = baker.make(Book, author=author, _quantity=5)
            books.extend(author_books)

        # Create 200 reviews (4 per book on average)
        for book in books:
            baker.make(Review, book=book, rating=fake.random_int(
                min=1, max=5), _quantity=4)

        # Test that aggregation queries work efficiently
        top_authors = Author.objects.top_authors(limit=5)
        assert len(top_authors) == 5

        authors_with_ratings = Author.objects.with_average_rating()
        assert authors_with_ratings.count() == 10
