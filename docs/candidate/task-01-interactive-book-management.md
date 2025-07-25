# Task 1: Interactive Book Management Interface

**Time Allocation**: 3-4 hours  
**Difficulty Level**: Mid-Level  
**Focus Areas**: Frontend Development, JavaScript/jQuery, User Experience

## Overview

Create a dynamic web interface for the DevTest book catalog system with search functionality, filtering capabilities, and AJAX-powered features. This task evaluates your frontend development skills, form handling abilities, and user experience design thinking.

## Project Setup

Follow the [Running the Project guide](../setup/running-project.md) to start the application with DevContainer, Docker Compose, or GitHub Codespaces.

## Task Requirements

### Core Features (Required)

1. **Dynamic Book Listing Page**
   - Display all books with title, author, genres, and average rating
   - Implement responsive design using Bootstrap 4
   - Add pagination for large book collections
   - Show book count and current page information

2. **Search Functionality**
   - Real-time search by book title
   - Search by author name
   - Search by genre
   - Display "No results found" message when appropriate
   - Clear search functionality

3. **Filtering System**
   - Filter by genre (dropdown or checkboxes)
   - Filter by rating range (1-5 stars)
   - Combine multiple filters
   - Show active filter indicators
   - Clear all filters option

4. **Review Management**
   - Form to add new reviews for books
   - Display existing reviews with ratings
   - Form validation (rating 1-5, optional comment)
   - Success/error messages for form submissions

5. **AJAX Implementation**
   - Load search results without page refresh
   - Apply filters dynamically
   - Submit review forms asynchronously
   - Show loading indicators during AJAX requests

### Technical Requirements

- Use Django templates with proper template inheritance
- Implement clean URL routing
- Use Bootstrap 4 for styling and responsive design
- Write clean, organized JavaScript/jQuery code
- Implement proper error handling
- Follow Django best practices for views and forms

### Bonus Features (Optional)

- Auto-complete for search fields
- Sort functionality (by title, author, rating, date)
- Book detail modal windows
- Favorite books functionality
- Reading list management
- Star rating input component
- Infinite scroll instead of pagination

## Implementation Guidelines

### 1. URL Structure
```python
# Suggested URL patterns
urlpatterns = [
    path('', views.book_list, name='book_list'),
    path('book/<int:book_id>/', views.book_detail, name='book_detail'),
    path('api/books/search/', views.book_search_api, name='book_search_api'),
    path('api/books/filter/', views.book_filter_api, name='book_filter_api'),
    path('api/reviews/add/', views.add_review_api, name='add_review_api'),
]
```

### 2. Database Queries
Utilize the existing model methods:
```python
# Use existing AuthorQuerySet methods
authors_with_ratings = Author.objects.with_average_rating()
top_authors = Author.objects.top_authors(limit=10)

# Efficient book queries with related data
books = Book.objects.select_related('author').prefetch_related('genres', 'review_set')
```

### 3. Frontend Structure
```
templates/
├── base.html (main layout)
├── book/
│   ├── list.html (main book listing)
│   ├── detail.html (book detail page)
│   └── components/
│       ├── book_card.html
│       ├── search_form.html
│       └── review_form.html
```

### 4. JavaScript Organization
```javascript
// Suggested JS structure
const BookCatalog = {
    search: {
        init: function() { /* search initialization */ },
        performSearch: function(query) { /* search logic */ }
    },
    filters: {
        init: function() { /* filter initialization */ },
        applyFilters: function() { /* filter logic */ }
    },
    reviews: {
        init: function() { /* review form initialization */ },
        submitReview: function(formData) { /* review submission */ }
    }
};
```

## Evaluation Criteria

### Code Quality (30%)
- Clean, readable code with proper comments
- Consistent naming conventions
- Proper separation of concerns
- DRY (Don't Repeat Yourself) principles

### Functionality (25%)
- All required features working correctly
- Proper error handling
- Form validation
- Edge case handling

### User Experience (20%)
- Intuitive interface design
- Responsive layout
- Loading indicators
- Clear feedback messages
- Accessibility considerations

### Technical Implementation (15%)
- Efficient AJAX implementation
- Proper Django view structure
- Database query optimization
- JavaScript code organization

### Frontend Skills (10%)
- Bootstrap 4 usage
- CSS customization
- JavaScript/jQuery proficiency
- Cross-browser compatibility

## Submission Guidelines

### What to Submit
1. All modified/created template files
2. Updated views.py with new view functions
3. Updated urls.py with new URL patterns
4. Any custom CSS/JavaScript files
5. Brief documentation of your approach

### Code Organization
- Follow Django project structure
- Use meaningful commit messages
- Include comments for complex logic
- Ensure code is properly formatted

### Testing Your Solution
Before submission, verify:
- All search functionality works
- Filters can be applied and cleared
- Review forms submit successfully
- Page is responsive on different screen sizes
- AJAX requests handle errors gracefully
- No JavaScript console errors

## Helpful Resources

- **Django Templates**: https://docs.djangoproject.com/en/stable/topics/templates/
- **Bootstrap 4 Documentation**: https://getbootstrap.com/docs/4.6/
- **jQuery Documentation**: https://api.jquery.com/
- **Django Forms**: https://docs.djangoproject.com/en/stable/topics/forms/

## Time Management Tips

- **Hour 1**: Set up basic templates and views
- **Hour 2**: Implement search functionality
- **Hour 3**: Add filtering and AJAX features
- **Hour 4**: Polish UI, add review forms, test thoroughly

## Common Pitfalls to Avoid

- Not handling empty search results
- Missing CSRF tokens in AJAX forms
- Inefficient database queries (N+1 problems)
- Not providing user feedback during loading
- Forgetting mobile responsiveness
- Not validating form inputs properly

Good luck with your implementation! Focus on creating a user-friendly interface while demonstrating solid technical skills.
