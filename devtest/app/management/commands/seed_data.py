from django.core.management.base import BaseCommand
from django.db import transaction
from devtest.app.models import Author, Genre, Book, Review
import random


class Command(BaseCommand):
    help = 'Populate the database with sample data for development and testing'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing data before seeding',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write('Clearing existing data...')
            Review.objects.all().delete()
            Book.objects.all().delete()
            Author.objects.all().delete()
            Genre.objects.all().delete()
            self.stdout.write(self.style.SUCCESS('Existing data cleared.'))

        with transaction.atomic():
            self.create_genres()
            self.create_authors()
            self.create_books()
            self.create_reviews()

        self.stdout.write(self.style.SUCCESS('Database seeded successfully!'))

    def create_genres(self):
        """Create sample genres"""
        genres_data = [
            'Fiction',
            'Science Fiction',
            'Fantasy',
            'Mystery',
            'Thriller',
            'Romance',
            'Historical Fiction',
            'Biography',
            'Non-Fiction',
            'Self-Help',
            'Business',
            'Technology',
            'Philosophy',
            'Psychology',
            'Horror',
            'Adventure',
            'Young Adult',
            'Children',
            'Poetry',
            'Drama',
            'Mythology',
            'Comedy',
            'Contemporary',
        ]

        for genre_name in genres_data:
            genre, created = Genre.objects.get_or_create(name=genre_name)
            if created:
                self.stdout.write(f'Created genre: {genre_name}')

    def create_authors(self):
        """Create sample authors"""
        authors_data = [
            'J.K. Rowling',
            'Stephen King',
            'Agatha Christie',
            'George Orwell',
            'Jane Austen',
            'Mark Twain',
            'Ernest Hemingway',
            'F. Scott Fitzgerald',
            'Harper Lee',
            'J.R.R. Tolkien',
            'Isaac Asimov',
            'Ray Bradbury',
            'Arthur Conan Doyle',
            'Charles Dickens',
            'William Shakespeare',
            'Maya Angelou',
            'Toni Morrison',
            'Margaret Atwood',
            'Neil Gaiman',
            'Terry Pratchett',
            'Douglas Adams',
            'Dan Brown',
            'John Grisham',
            'Michael Crichton',
            'Paulo Coelho',
            'Haruki Murakami',
            'Gabriel García Márquez',
            'Chinua Achebe',
            'Salman Rushdie',
            'Zadie Smith'
        ]

        for author_name in authors_data:
            author, created = Author.objects.get_or_create(name=author_name)
            if created:
                self.stdout.write(f'Created author: {author_name}')

    def create_books(self):
        """Create sample books with author and genre relationships"""
        books_data = [
            {
                'title': 'Harry Potter and the Philosopher\'s Stone',
                'author': 'J.K. Rowling',
                'genres': ['Fantasy', 'Young Adult', 'Adventure']
            },
            {
                'title': 'The Shining',
                'author': 'Stephen King',
                'genres': ['Horror', 'Thriller', 'Fiction']
            },
            {
                'title': 'Murder on the Orient Express',
                'author': 'Agatha Christie',
                'genres': ['Mystery', 'Fiction', 'Thriller']
            },
            {
                'title': '1984',
                'author': 'George Orwell',
                'genres': ['Science Fiction', 'Fiction', 'Philosophy']
            },
            {
                'title': 'Pride and Prejudice',
                'author': 'Jane Austen',
                'genres': ['Romance', 'Fiction', 'Historical Fiction']
            },
            {
                'title': 'The Adventures of Tom Sawyer',
                'author': 'Mark Twain',
                'genres': ['Adventure', 'Fiction', 'Children']
            },
            {
                'title': 'The Old Man and the Sea',
                'author': 'Ernest Hemingway',
                'genres': ['Fiction', 'Adventure', 'Drama']
            },
            {
                'title': 'The Great Gatsby',
                'author': 'F. Scott Fitzgerald',
                'genres': ['Fiction', 'Historical Fiction', 'Drama']
            },
            {
                'title': 'To Kill a Mockingbird',
                'author': 'Harper Lee',
                'genres': ['Fiction', 'Historical Fiction', 'Drama']
            },
            {
                'title': 'The Lord of the Rings',
                'author': 'J.R.R. Tolkien',
                'genres': ['Fantasy', 'Adventure', 'Fiction']
            },
            {
                'title': 'Foundation',
                'author': 'Isaac Asimov',
                'genres': ['Science Fiction', 'Fiction']
            },
            {
                'title': 'Fahrenheit 451',
                'author': 'Ray Bradbury',
                'genres': ['Science Fiction', 'Fiction', 'Philosophy']
            },
            {
                'title': 'The Hound of the Baskervilles',
                'author': 'Arthur Conan Doyle',
                'genres': ['Mystery', 'Fiction', 'Adventure']
            },
            {
                'title': 'A Tale of Two Cities',
                'author': 'Charles Dickens',
                'genres': ['Historical Fiction', 'Fiction', 'Drama']
            },
            {
                'title': 'Hamlet',
                'author': 'William Shakespeare',
                'genres': ['Drama', 'Fiction', 'Poetry']
            },
            {
                'title': 'I Know Why the Caged Bird Sings',
                'author': 'Maya Angelou',
                'genres': ['Biography', 'Non-Fiction']
            },
            {
                'title': 'Beloved',
                'author': 'Toni Morrison',
                'genres': ['Fiction', 'Historical Fiction', 'Drama']
            },
            {
                'title': 'The Handmaid\'s Tale',
                'author': 'Margaret Atwood',
                'genres': ['Science Fiction', 'Fiction', 'Philosophy']
            },
            {
                'title': 'American Gods',
                'author': 'Neil Gaiman',
                'genres': ['Fantasy', 'Fiction', 'Mythology']
            },
            {
                'title': 'Good Omens',
                'author': 'Terry Pratchett',
                'genres': ['Fantasy', 'Fiction', 'Comedy']
            },
            {
                'title': 'The Hitchhiker\'s Guide to the Galaxy',
                'author': 'Douglas Adams',
                'genres': ['Science Fiction', 'Fiction', 'Comedy']
            },
            {
                'title': 'The Da Vinci Code',
                'author': 'Dan Brown',
                'genres': ['Thriller', 'Mystery', 'Fiction']
            },
            {
                'title': 'The Firm',
                'author': 'John Grisham',
                'genres': ['Thriller', 'Fiction', 'Mystery']
            },
            {
                'title': 'Jurassic Park',
                'author': 'Michael Crichton',
                'genres': ['Science Fiction', 'Thriller', 'Adventure']
            },
            {
                'title': 'The Alchemist',
                'author': 'Paulo Coelho',
                'genres': ['Fiction', 'Philosophy', 'Self-Help']
            },
            {
                'title': 'Norwegian Wood',
                'author': 'Haruki Murakami',
                'genres': ['Fiction', 'Romance', 'Drama']
            },
            {
                'title': 'One Hundred Years of Solitude',
                'author': 'Gabriel García Márquez',
                'genres': ['Fiction', 'Historical Fiction', 'Drama']
            },
            {
                'title': 'Things Fall Apart',
                'author': 'Chinua Achebe',
                'genres': ['Fiction', 'Historical Fiction', 'Drama']
            },
            {
                'title': 'Midnight\'s Children',
                'author': 'Salman Rushdie',
                'genres': ['Fiction', 'Historical Fiction', 'Drama']
            },
            {
                'title': 'White Teeth',
                'author': 'Zadie Smith',
                'genres': ['Fiction', 'Drama', 'Contemporary']
            }
        ]

        for book_data in books_data:
            try:
                author = Author.objects.get(name=book_data['author'])
                book, created = Book.objects.get_or_create(
                    title=book_data['title'],
                    author=author
                )

                if created:
                    # Add genres to the book
                    for genre_name in book_data['genres']:
                        try:
                            genre = Genre.objects.get(name=genre_name)
                            book.genres.add(genre)
                        except Genre.DoesNotExist:
                            self.stdout.write(
                                self.style.WARNING(f'Genre "{genre_name}" not found for book "{book_data["title"]}"')
                            )

                    self.stdout.write(f'Created book: {book_data["title"]} by {book_data["author"]}')

            except Author.DoesNotExist:
                self.stdout.write(
                    self.style.WARNING(f'Author "{book_data["author"]}" not found for book "{book_data["title"]}"')
                )

    def create_reviews(self):
        """Create sample reviews for books"""
        review_comments = [
            "An absolutely captivating read! Couldn't put it down.",
            "Well-written and engaging. Highly recommend.",
            "A masterpiece of storytelling. Brilliant character development.",
            "Good book, but felt a bit slow in the middle.",
            "Excellent plot twists and great pacing.",
            "Not my favorite, but still worth reading.",
            "Outstanding work! One of the best books I've read this year.",
            "Interesting concept but execution could be better.",
            "A classic that stands the test of time.",
            "Beautifully written with deep emotional impact.",
            "Great for fans of the genre, but might not appeal to everyone.",
            "Compelling story with memorable characters.",
            "A bit predictable but still enjoyable.",
            "Thought-provoking and well-researched.",
            "Fast-paced and exciting from start to finish.",
            "The author's best work yet!",
            "Good character development but weak ending.",
            "A page-turner that keeps you guessing.",
            "Solid writing and interesting themes.",
            "Not what I expected, but pleasantly surprised.",
            "A bit too long but worth the read.",
            "Excellent world-building and atmosphere.",
            "Simple yet profound. A quick but meaningful read.",
            "Great dialogue and realistic characters.",
            "A bit dated but still relevant and engaging."
        ]

        books = Book.objects.all()

        for book in books:
            # Create 2-5 reviews per book
            num_reviews = random.randint(2, 5)

            for _ in range(num_reviews):
                rating = random.choices(
                    [1, 2, 3, 4, 5],
                    weights=[5, 10, 20, 35, 30],  # Weighted towards higher ratings
                    k=1
                )[0]

                comment = random.choice(review_comments)

                Review.objects.create(
                    book=book,
                    rating=rating,
                    comment=comment
                )

            self.stdout.write(f'Created {num_reviews} reviews for: {book.title}')
