# Task 1: Interactive Book Management Interface

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

Good luck with your implementation! Focus on creating a user-friendly interface while demonstrating solid technical skills.
