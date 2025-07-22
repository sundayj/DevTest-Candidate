from django.shortcuts import render
from django.db.models import Avg, Count
from .models import Book, Author, Genre, Review


def landing_page(request):
    """Landing page view displaying library statistics and featured content."""

    # Get some basic statistics
    total_books = Book.objects.count()
    total_authors = Author.objects.count()
    total_genres = Genre.objects.count()
    total_reviews = Review.objects.count()

    # Get featured books (books with highest average ratings)
    featured_books = Book.objects.annotate(
        avg_rating=Avg('review__rating'),
        review_count=Count('review')
    ).filter(review_count__gt=0).order_by('-avg_rating')[:6]

    # Get top authors (using the existing queryset method)
    top_authors = Author.objects.top_authors(limit=5)

    # Get recent reviews
    recent_reviews = Review.objects.select_related(
        'book', 'book__author').order_by('-created_at')[:5]

    context = {
        'total_books': total_books,
        'total_authors': total_authors,
        'total_genres': total_genres,
        'total_reviews': total_reviews,
        'featured_books': featured_books,
        'top_authors': top_authors,
        'recent_reviews': recent_reviews,
    }

    return render(request, 'app/landing_page.html', context)
