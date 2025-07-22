# Database Seed Data Guide

This guide explains how to populate the DevTest database with sample data for development, testing, and interviews.

## Overview

The DevTest project includes a Django management command that populates the database with realistic sample data including:

- **20 Genres**: Fiction, Science Fiction, Fantasy, Mystery, Thriller, Romance, etc.
- **30 Authors**: Well-known authors from various backgrounds and time periods
- **30 Books**: Classic and popular books with proper author and genre relationships
- **Reviews**: 2-5 random reviews per book with realistic ratings and comments

## Quick Start

### Populate Database with Sample Data

```bash
# Using Docker Compose
docker-compose exec web python manage.py seed_data

# Using DevContainer or Codespaces (from the IDE terminal)
python manage.py seed_data

# If using a host terminal
devcontainer exec --workspace-folder . python manage.py seed_data
```

### Clear and Repopulate Database

```bash
# Clear existing data and add fresh seed data
docker-compose exec web python manage.py seed_data --clear
# Or if using DevContainers/Codespaces: python manage.py seed_data --clear
```

## Command Options

### Basic Usage
```bash
python manage.py seed_data
```
- Adds sample data to the database
- Skips items that already exist (uses `get_or_create`)
- Safe to run multiple times

### Clear and Seed
```bash
python manage.py seed_data --clear
```
- **⚠️ Warning**: Deletes ALL existing data first
- Then populates with fresh sample data
- Use with caution in development environments

### Help
```bash
python manage.py help seed_data
```
- Shows all available options and usage information

## Sample Data Details

### Authors (30 total)
The seed data includes diverse, well-known authors:
- **Classic Literature**: Jane Austen, Charles Dickens, William Shakespeare
- **Modern Fiction**: J.K. Rowling, Stephen King, Margaret Atwood
- **Science Fiction**: Isaac Asimov, Ray Bradbury, Douglas Adams
- **International**: Haruki Murakami, Gabriel García Márquez, Chinua Achebe
- **Contemporary**: Zadie Smith, Neil Gaiman, Toni Morrison

### Genres (20 total)
Comprehensive genre coverage:
- **Fiction Categories**: Fiction, Historical Fiction, Science Fiction, Fantasy
- **Popular Genres**: Mystery, Thriller, Romance, Horror, Adventure
- **Specialized**: Biography, Non-Fiction, Self-Help, Business, Technology
- **Literary**: Poetry, Drama, Philosophy, Psychology
- **Age Groups**: Young Adult, Children

### Books (30 total)
Each book includes:
- **Title and Author**: Proper relationships to Author model
- **Multiple Genres**: Books can belong to multiple genres via ManyToMany relationship
- **Famous Works**: Harry Potter, 1984, Pride and Prejudice, The Great Gatsby, etc.

### Reviews (2-5 per book)
Realistic review data:
- **Ratings**: 1-5 stars, weighted towards higher ratings (more 4s and 5s)
- **Comments**: 25 different realistic review comments
- **Variety**: Each book gets a random number of reviews (2-5)

## Use Cases

### Development
```bash
# Set up fresh development environment
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py seed_data
# Or if using DevContainers/Codespaces: python manage.py seed_data
```

### Testing
```bash
# Reset database for testing
docker-compose exec web python manage.py seed_data --clear
# Or if using DevContainers/Codespaces: python manage.py seed_data --clear
```

### Interviews
```bash
# Prepare consistent data for candidate assessment
docker-compose exec web python manage.py seed_data --clear
# Or if using DevContainers/Codespaces: python manage.py seed_data --clear
```

### Demonstrations
- The seeded data provides a rich dataset for demonstrating:
  - Complex database relationships
  - QuerySet operations (like `Author.objects.top_authors()`)
  - Search and filtering functionality
  - Review aggregation and statistics

## Data Relationships

The seed data demonstrates all model relationships:

```python
# Author → Books (One-to-Many)
author = Author.objects.get(name="J.K. Rowling")
books = author.book_set.all()

# Book → Genres (Many-to-Many)
book = Book.objects.get(title="Harry Potter and the Philosopher's Stone")
genres = book.genres.all()  # Fantasy, Young Adult, Adventure

# Book → Reviews (One-to-Many)
reviews = book.review_set.all()

# Advanced QuerySet usage
top_authors = Author.objects.top_authors()  # Uses custom QuerySet method
```

## Verification

After running the seed command, verify the data:

### Check Counts
```bash
# Using Django shell
docker-compose exec web python manage.py shell

>>> from devtest.app.models import Author, Book, Genre, Review
>>> Author.objects.count()  # Should be 30
>>> Book.objects.count()    # Should be 30
>>> Genre.objects.count()   # Should be 20
>>> Review.objects.count()  # Should be 90-150 (2-5 per book)
```

### Test Relationships
```bash
>>> # Test the custom QuerySet method
>>> Author.objects.top_authors()
>>> 
>>> # Test Many-to-Many relationships
>>> Book.objects.get(title="1984").genres.all()
>>> 
>>> # Test review aggregation
>>> from django.db.models import Avg
>>> Book.objects.annotate(avg_rating=Avg('review__rating'))
```

### Admin Interface
Visit http://localhost:8001/admin to browse the seeded data:
1. Create a superuser: `docker-compose exec web python manage.py createsuperuser`
2. Login and explore Authors, Books, Genres, and Reviews

## Troubleshooting

### Import Errors
If you see import errors, ensure you're running the command from the correct directory and the Django app is properly configured.

### Database Connection Issues
Make sure the database container is running:
```bash
docker-compose ps  # Check if 'db' service is running
docker-compose up -d db  # Start database if needed
```

### Permission Issues
If running locally (not in Docker), ensure proper database permissions and that migrations have been applied:
```bash
python manage.py migrate
```

## Customization

To modify the seed data, edit `devtest/app/management/commands/seed_data.py`:

- **Add more genres**: Extend the `genres_data` list
- **Add more authors**: Extend the `authors_data` list  
- **Add more books**: Extend the `books_data` list with proper author/genre relationships
- **Modify review comments**: Update the `review_comments` list
- **Change review distribution**: Adjust the rating weights in `create_reviews()`

## Integration with Interview System

The seed data is particularly useful for technical interviews:

- **Consistent Starting Point**: All candidates work with the same dataset
- **Rich Relationships**: Demonstrates complex database modeling
- **Realistic Data**: Books and authors candidates will recognize
- **Testing Scenarios**: Perfect for debugging tasks and optimization challenges

For interview usage, always run with `--clear` to ensure a clean, consistent starting state:

```bash
# Before each interview session
docker-compose exec web python manage.py seed_data --clear
# Or if using DevContainers/Codespaces: python manage.py seed_data --clear
```

This ensures all candidates start with identical data and prevents any previous work from affecting the assessment.
