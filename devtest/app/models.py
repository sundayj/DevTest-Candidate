from django.db import models
from django.db.models import Avg, Count


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


class Author(models.Model):
    name = models.CharField(max_length=100)

    objects = AuthorQuerySet.as_manager()

    def __str__(self) -> str:  # pragma: no cover - trivial
        return self.name


class Genre(models.Model):
    name = models.CharField(max_length=50)

    def __str__(self) -> str:  # pragma: no cover - trivial
        return self.name


class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.ForeignKey(Author, on_delete=models.CASCADE)
    genres = models.ManyToManyField(Genre, blank=True)

    def __str__(self) -> str:  # pragma: no cover - trivial
        return self.title


class Review(models.Model):
    book = models.ForeignKey(Book, on_delete=models.CASCADE)
    rating = models.PositiveSmallIntegerField()
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:  # pragma: no cover - trivial
        return f"Review for {self.book}"  # pragma: no cover - trivial
