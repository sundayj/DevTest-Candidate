import pytest
from faker import Faker
from model_bakery import baker

from devtest.app.models import Author, Genre, Book, Review


fake = Faker()


@pytest.mark.django_db
class TestAuthor:
    """Test cases for Author model."""

    def test_author_creation(self, author):
        """Test that an author can be created."""
        assert author.id is not None
        assert isinstance(author.name, str)
        assert len(author.name) > 0

    def test_author_str_representation(self, author):
        """Test the string representation of an author."""
        assert str(author) == author.name

    def test_author_with_average_rating(self, multiple_books_with_reviews):
        """Test the with_average_rating queryset method."""
        authors_with_ratings = Author.objects.with_average_rating()

        for author in authors_with_ratings:
            assert hasattr(author, 'avg_rating')
            assert hasattr(author, 'book_count')
            assert hasattr(author, 'review_count')

            if author.avg_rating is not None:
                assert 1 <= author.avg_rating <= 5
            assert author.book_count >= 0
            assert author.review_count >= 0

    def test_top_authors(self, multiple_books_with_reviews):
        """Test the top_authors queryset method."""
        top_authors = Author.objects.top_authors(limit=3)

        assert len(top_authors) <= 3

        # Check that authors are ordered by average rating (descending)
        ratings = [
            author.avg_rating for author in top_authors if author.avg_rating is not None]
        assert ratings == sorted(ratings, reverse=True)


@pytest.mark.django_db
class TestGenre:
    """Test cases for Genre model."""

    def test_genre_creation(self, genre):
        """Test that a genre can be created."""
        assert genre.id is not None
        assert isinstance(genre.name, str)
        assert len(genre.name) > 0

    def test_genre_str_representation(self, genre):
        """Test the string representation of a genre."""
        assert str(genre) == genre.name


@pytest.mark.django_db
class TestBook:
    """Test cases for Book model."""

    def test_book_creation(self, book):
        """Test that a book can be created."""
        assert book.id is not None
        assert isinstance(book.title, str)
        assert len(book.title) > 0
        assert book.author is not None

    def test_book_str_representation(self, book):
        """Test the string representation of a book."""
        assert str(book) == book.title

    def test_book_author_relationship(self, author):
        """Test the foreign key relationship with Author."""
        book = baker.make(Book, author=author, title=fake.sentence(nb_words=3))
        assert book.author == author
        assert book in author.book_set.all()

    def test_book_genres_relationship(self, book, genre):
        """Test the many-to-many relationship with Genre."""
        additional_genre = baker.make(Genre, name=fake.word())
        book.genres.add(additional_genre)

        assert genre in book.genres.all()
        assert additional_genre in book.genres.all()
        assert book.genres.count() == 2

    def test_book_cascade_delete_with_author(self, book):
        """Test that deleting an author cascades to delete books."""
        author = book.author
        author_id = author.id
        book_id = book.id

        author.delete()

        assert not Author.objects.filter(id=author_id).exists()
        assert not Book.objects.filter(id=book_id).exists()


@pytest.mark.django_db
class TestReview:
    """Test cases for Review model."""

    def test_review_creation(self, review):
        """Test that a review can be created."""
        assert review.id is not None
        assert isinstance(review.rating, int)
        assert 1 <= review.rating <= 5
        assert review.book is not None
        assert review.created_at is not None

    def test_review_str_representation(self, review):
        """Test the string representation of a review."""
        expected_str = f"Review for {review.book}"
        assert str(review) == expected_str

    def test_review_book_relationship(self, book):
        """Test the foreign key relationship with Book."""
        review = baker.make(
            Review,
            book=book,
            rating=fake.random_int(min=1, max=5),
            comment=fake.text(max_nb_chars=200),
        )
        assert review.book == book
        assert review in book.review_set.all()

    def test_review_cascade_delete_with_book(self, review):
        """Test that deleting a book cascades to delete reviews."""
        book = review.book
        book_id = book.id
        review_id = review.id

        book.delete()

        assert not Book.objects.filter(id=book_id).exists()
        assert not Review.objects.filter(id=review_id).exists()

    def test_review_rating_validation(self, book):
        """Test that review rating is properly validated."""
        # Test valid ratings
        for rating in [1, 2, 3, 4, 5]:
            review = baker.make(Review, book=book, rating=rating)
            assert review.rating == rating

    def test_review_optional_comment(self, book):
        """Test that review comment is optional."""
        review = baker.make(Review, book=book, rating=5, comment="")
        assert review.comment == ""

        review_with_comment = baker.make(
            Review, book=book, rating=4, comment=fake.text(max_nb_chars=100)
        )
        assert len(review_with_comment.comment) > 0

    def test_review_created_at_auto_now_add(self, book):
        """Test that created_at is automatically set."""
        review = baker.make(Review, book=book, rating=5)
        assert review.created_at is not None
