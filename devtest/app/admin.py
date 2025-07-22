from django.contrib import admin
from .models import Author, Genre, Book, Review


# Register your models here.
@admin.register(Author)
class AuthorAdmin(admin.ModelAdmin):
    list_display = ('name',)
    search_fields = ('name',)


@admin.register(Genre)
class GenreAdmin(admin.ModelAdmin):
    list_display = ('name',)
    search_fields = ('name',)


@admin.register(Book)
class BookAdmin(admin.ModelAdmin):
    list_display = ('title', 'author')
    list_filter = ('author', 'genres')
    search_fields = ('title', 'author__name')
    filter_horizontal = ('genres',)


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ('book', 'rating', 'created_at')
    list_filter = ('rating', 'created_at')
    search_fields = ('book__title', 'comment')
    readonly_fields = ('created_at',)
