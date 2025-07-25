# Task 9: Data Import/Export System

**Time Allocation**: 2-3 hours  
**Difficulty Level**: Mid-Level  
**Focus Areas**: Data Processing, File Handling, System Integration

## Overview

Create a comprehensive data import/export system for the DevTest book catalog that can handle various file formats (CSV, JSON, XML) and provide robust data validation, error handling, and progress tracking. This task evaluates your data processing skills, file handling capabilities, and system integration knowledge.

## Project Setup

Follow the [Running the Project guide](../setup/running-project.md) to start the application with DevContainer, Docker Compose, or GitHub Codespaces.

## Task Requirements

### Core Import/Export Features (Required)

1. **Data Import System**
   - Support CSV, JSON, and XML file formats
   - Import books, authors, genres, and reviews
   - Data validation and error handling
   - Progress tracking for large files
   - Duplicate detection and handling

2. **Data Export System**
   - Export data in CSV, JSON, and XML formats
   - Flexible export options (all data, filtered data)
   - Include related data (books with reviews, authors with books)
   - Streaming export for large datasets
   - Export scheduling and automation

3. **Web Interface**
   - File upload interface with drag-and-drop
   - Import/export progress indicators
   - Error reporting and validation feedback
   - Download links for exported files
   - Import/export history

4. **Management Commands**
   - Command-line import/export tools
   - Batch processing capabilities
   - Automated data synchronization
   - Data backup and restore functionality

### Advanced Features (Optional)

- Excel file support (.xlsx)
- Real-time data synchronization
- API-based import/export
- Data transformation and mapping
- Incremental imports/exports
- Data archiving system

## Implementation Guidelines

### 1. Data Models and Structure

#### Import/Export Tracking Models
```python
# models.py - Add import/export tracking
from django.db import models
from django.contrib.auth.models import User
import uuid

class ImportExportJob(models.Model):
    JOB_TYPES = [
        ('import', 'Import'),
        ('export', 'Export'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
    ]
    
    FORMAT_CHOICES = [
        ('csv', 'CSV'),
        ('json', 'JSON'),
        ('xml', 'XML'),
        ('xlsx', 'Excel'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    job_type = models.CharField(max_length=10, choices=JOB_TYPES)
    format = models.CharField(max_length=10, choices=FORMAT_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    file_name = models.CharField(max_length=255)
    file_path = models.FileField(upload_to='import_export/', null=True, blank=True)
    
    total_records = models.IntegerField(default=0)
    processed_records = models.IntegerField(default=0)
    successful_records = models.IntegerField(default=0)
    failed_records = models.IntegerField(default=0)
    
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    error_log = models.TextField(blank=True)
    result_summary = models.JSONField(default=dict)
    
    class Meta:
        ordering = ['-created_at']

class ImportExportError(models.Model):
    job = models.ForeignKey(ImportExportJob, on_delete=models.CASCADE, related_name='errors')
    row_number = models.IntegerField()
    field_name = models.CharField(max_length=100, blank=True)
    error_message = models.TextField()
    raw_data = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['row_number']
```

### 2. Import System Implementation

#### Base Import Service
```python
# services/import_service.py
import csv
import json
import xml.etree.ElementTree as ET
from typing import Dict, List, Any, Generator
from django.db import transaction
from django.core.exceptions import ValidationError
from django.utils import timezone
from io import StringIO

from ..models import Author, Book, Genre, Review, ImportExportJob, ImportExportError

class BaseImporter:
    """Base class for data importers."""
    
    def __init__(self, job: ImportExportJob):
        self.job = job
        self.errors = []
        self.processed_count = 0
        self.success_count = 0
        self.error_count = 0
    
    def import_data(self, file_content: str) -> Dict[str, Any]:
        """Main import method."""
        try:
            self.job.status = 'processing'
            self.job.started_at = timezone.now()
            self.job.save()
            
            # Parse and validate data
            data = self.parse_file(file_content)
            self.job.total_records = len(data)
            self.job.save()
            
            # Process data in batches
            batch_size = 100
            for i in range(0, len(data), batch_size):
                batch = data[i:i + batch_size]
                self.process_batch(batch, i)
                
                # Update progress
                self.job.processed_records = min(i + batch_size, len(data))
                self.job.successful_records = self.success_count
                self.job.failed_records = self.error_count
                self.job.save()
            
            # Complete job
            self.job.status = 'completed' if self.error_count == 0 else 'completed'
            self.job.completed_at = timezone.now()
            self.job.result_summary = {
                'total': len(data),
                'successful': self.success_count,
                'failed': self.error_count,
                'errors': len(self.errors)
            }
            self.job.save()
            
            return self.job.result_summary
            
        except Exception as e:
            self.job.status = 'failed'
            self.job.error_log = str(e)
            self.job.completed_at = timezone.now()
            self.job.save()
            raise
    
    def parse_file(self, content: str) -> List[Dict[str, Any]]:
        """Parse file content - to be implemented by subclasses."""
        raise NotImplementedError
    
    def process_batch(self, batch: List[Dict[str, Any]], start_index: int):
        """Process a batch of records."""
        for i, record in enumerate(batch):
            row_number = start_index + i + 1
            try:
                with transaction.atomic():
                    self.process_record(record, row_number)
                    self.success_count += 1
            except Exception as e:
                self.handle_error(row_number, str(e), record)
                self.error_count += 1
            
            self.processed_count += 1
    
    def process_record(self, record: Dict[str, Any], row_number: int):
        """Process a single record - to be implemented by subclasses."""
        raise NotImplementedError
    
    def handle_error(self, row_number: int, error_message: str, 
                    raw_data: Dict[str, Any], field_name: str = ''):
        """Handle and log errors."""
        error = ImportExportError.objects.create(
            job=self.job,
            row_number=row_number,
            field_name=field_name,
            error_message=error_message,
            raw_data=raw_data
        )
        self.errors.append(error)

class CSVImporter(BaseImporter):
    """CSV file importer."""
    
    def parse_file(self, content: str) -> List[Dict[str, Any]]:
        """Parse CSV content."""
        reader = csv.DictReader(StringIO(content))
        return list(reader)

class JSONImporter(BaseImporter):
    """JSON file importer."""
    
    def parse_file(self, content: str) -> List[Dict[str, Any]]:
        """Parse JSON content."""
        data = json.loads(content)
        if isinstance(data, dict) and 'data' in data:
            return data['data']
        elif isinstance(data, list):
            return data
        else:
            raise ValueError("Invalid JSON format. Expected list or object with 'data' key.")

class XMLImporter(BaseImporter):
    """XML file importer."""
    
    def parse_file(self, content: str) -> List[Dict[str, Any]]:
        """Parse XML content."""
        root = ET.fromstring(content)
        data = []
        
        # Assume XML structure: <root><item>...</item></root>
        for item in root:
            record = {}
            for child in item:
                record[child.tag] = child.text
            data.append(record)
        
        return data

class BookImporter(CSVImporter):
    """Specialized importer for books."""
    
    def process_record(self, record: Dict[str, Any], row_number: int):
        """Process a book record."""
        # Validate required fields
        required_fields = ['title', 'author_name']
        for field in required_fields:
            if not record.get(field):
                raise ValidationError(f"Missing required field: {field}")
        
        # Get or create author
        author_name = record['author_name'].strip()
        author, created = Author.objects.get_or_create(
            name=author_name,
            defaults={'name': author_name}
        )
        
        # Create book
        book_data = {
            'title': record['title'].strip(),
            'author': author,
        }
        
        if record.get('description'):
            book_data['description'] = record['description'].strip()
        
        # Check for duplicates
        existing_book = Book.objects.filter(
            title=book_data['title'],
            author=author
        ).first()
        
        if existing_book:
            if record.get('update_existing', '').lower() == 'true':
                # Update existing book
                for key, value in book_data.items():
                    if key != 'author':  # Don't update author
                        setattr(existing_book, key, value)
                existing_book.save()
                book = existing_book
            else:
                raise ValidationError(f"Book '{book_data['title']}' by {author_name} already exists")
        else:
            book = Book.objects.create(**book_data)
        
        # Handle genres
        if record.get('genres'):
            genre_names = [g.strip() for g in record['genres'].split(',')]
            for genre_name in genre_names:
                if genre_name:
                    genre, created = Genre.objects.get_or_create(
                        name=genre_name,
                        defaults={'name': genre_name}
                    )
                    book.genres.add(genre)
        
        return book

class ReviewImporter(CSVImporter):
    """Specialized importer for reviews."""
    
    def process_record(self, record: Dict[str, Any], row_number: int):
        """Process a review record."""
        # Validate required fields
        required_fields = ['book_title', 'author_name', 'rating']
        for field in required_fields:
            if not record.get(field):
                raise ValidationError(f"Missing required field: {field}")
        
        # Find book
        try:
            book = Book.objects.select_related('author').get(
                title=record['book_title'].strip(),
                author__name=record['author_name'].strip()
            )
        except Book.DoesNotExist:
            raise ValidationError(f"Book '{record['book_title']}' by {record['author_name']} not found")
        
        # Validate rating
        try:
            rating = int(record['rating'])
            if not 1 <= rating <= 5:
                raise ValidationError("Rating must be between 1 and 5")
        except ValueError:
            raise ValidationError("Rating must be a valid integer")
        
        # Create review
        review_data = {
            'book': book,
            'rating': rating,
        }
        
        if record.get('comment'):
            review_data['comment'] = record['comment'].strip()
        
        # Handle user (if provided)
        if record.get('user_email'):
            from django.contrib.auth.models import User
            try:
                user = User.objects.get(email=record['user_email'])
                review_data['user'] = user
            except User.DoesNotExist:
                # Create anonymous review or skip
                pass
        
        review = Review.objects.create(**review_data)
        return review
```

### 3. Export System Implementation

#### Export Service
```python
# services/export_service.py
import csv
import json
import xml.etree.ElementTree as ET
from typing import Dict, List, Any, Generator
from django.http import HttpResponse, StreamingHttpResponse
from django.db.models import QuerySet
from django.utils import timezone
from io import StringIO

class BaseExporter:
    """Base class for data exporters."""
    
    def __init__(self, job: ImportExportJob):
        self.job = job
    
    def export_data(self, queryset: QuerySet, fields: List[str] = None) -> str:
        """Main export method."""
        try:
            self.job.status = 'processing'
            self.job.started_at = timezone.now()
            self.job.total_records = queryset.count()
            self.job.save()
            
            # Generate export content
            content = self.generate_content(queryset, fields)
            
            # Complete job
            self.job.status = 'completed'
            self.job.completed_at = timezone.now()
            self.job.processed_records = self.job.total_records
            self.job.successful_records = self.job.total_records
            self.job.save()
            
            return content
            
        except Exception as e:
            self.job.status = 'failed'
            self.job.error_log = str(e)
            self.job.completed_at = timezone.now()
            self.job.save()
            raise
    
    def generate_content(self, queryset: QuerySet, fields: List[str] = None) -> str:
        """Generate export content - to be implemented by subclasses."""
        raise NotImplementedError
    
    def serialize_record(self, obj: Any, fields: List[str] = None) -> Dict[str, Any]:
        """Serialize a single record."""
        if hasattr(obj, '_meta'):
            # Django model
            data = {}
            model_fields = fields or [f.name for f in obj._meta.fields]
            
            for field_name in model_fields:
                try:
                    value = getattr(obj, field_name)
                    if hasattr(value, 'isoformat'):  # DateTime
                        data[field_name] = value.isoformat()
                    elif hasattr(value, 'pk'):  # Foreign key
                        data[field_name] = str(value)
                    else:
                        data[field_name] = value
                except AttributeError:
                    data[field_name] = None
            
            return data
        else:
            return dict(obj) if hasattr(obj, 'items') else {'value': str(obj)}

class CSVExporter(BaseExporter):
    """CSV file exporter."""
    
    def generate_content(self, queryset: QuerySet, fields: List[str] = None) -> str:
        """Generate CSV content."""
        output = StringIO()
        
        if queryset.exists():
            first_obj = queryset.first()
            if not fields:
                fields = [f.name for f in first_obj._meta.fields]
            
            writer = csv.DictWriter(output, fieldnames=fields)
            writer.writeheader()
            
            batch_size = 1000
            for i in range(0, queryset.count(), batch_size):
                batch = queryset[i:i + batch_size]
                for obj in batch:
                    row_data = self.serialize_record(obj, fields)
                    writer.writerow(row_data)
                
                # Update progress
                self.job.processed_records = min(i + batch_size, queryset.count())
                self.job.save()
        
        return output.getvalue()

class JSONExporter(BaseExporter):
    """JSON file exporter."""
    
    def generate_content(self, queryset: QuerySet, fields: List[str] = None) -> str:
        """Generate JSON content."""
        data = []
        
        batch_size = 1000
        for i in range(0, queryset.count(), batch_size):
            batch = queryset[i:i + batch_size]
            for obj in batch:
                data.append(self.serialize_record(obj, fields))
            
            # Update progress
            self.job.processed_records = min(i + batch_size, queryset.count())
            self.job.save()
        
        return json.dumps({
            'exported_at': timezone.now().isoformat(),
            'total_records': len(data),
            'data': data
        }, indent=2)

class XMLExporter(BaseExporter):
    """XML file exporter."""
    
    def generate_content(self, queryset: QuerySet, fields: List[str] = None) -> str:
        """Generate XML content."""
        root = ET.Element('export')
        root.set('exported_at', timezone.now().isoformat())
        root.set('total_records', str(queryset.count()))
        
        data_element = ET.SubElement(root, 'data')
        
        batch_size = 1000
        for i in range(0, queryset.count(), batch_size):
            batch = queryset[i:i + batch_size]
            for obj in batch:
                item_element = ET.SubElement(data_element, 'item')
                record_data = self.serialize_record(obj, fields)
                
                for key, value in record_data.items():
                    field_element = ET.SubElement(item_element, key)
                    field_element.text = str(value) if value is not None else ''
            
            # Update progress
            self.job.processed_records = min(i + batch_size, queryset.count())
            self.job.save()
        
        return ET.tostring(root, encoding='unicode')

class BookExporter:
    """Specialized exporter for books with related data."""
    
    @staticmethod
    def get_books_with_details(filters: Dict[str, Any] = None) -> QuerySet:
        """Get books queryset with related data."""
        queryset = Book.objects.select_related('author').prefetch_related(
            'genres', 'review_set'
        )
        
        if filters:
            if filters.get('genre_ids'):
                queryset = queryset.filter(genres__id__in=filters['genre_ids'])
            
            if filters.get('author_ids'):
                queryset = queryset.filter(author__id__in=filters['author_ids'])
            
            if filters.get('min_rating'):
                from django.db.models import Avg
                queryset = queryset.annotate(
                    avg_rating=Avg('review__rating')
                ).filter(avg_rating__gte=filters['min_rating'])
        
        return queryset.distinct()
    
    @staticmethod
    def serialize_book_with_details(book: Book) -> Dict[str, Any]:
        """Serialize book with all related data."""
        return {
            'id': book.id,
            'title': book.title,
            'author_name': book.author.name,
            'author_id': book.author.id,
            'description': book.description,
            'genres': [g.name for g in book.genres.all()],
            'genre_ids': [g.id for g in book.genres.all()],
            'reviews': [
                {
                    'id': r.id,
                    'rating': r.rating,
                    'comment': r.comment,
                    'created_at': r.created_at.isoformat(),
                    'user_id': r.user.id if r.user else None,
                }
                for r in book.review_set.all()
            ],
            'average_rating': sum(r.rating for r in book.review_set.all()) / book.review_set.count() if book.review_set.exists() else None,
            'review_count': book.review_set.count(),
            'created_at': book.created_at.isoformat() if hasattr(book, 'created_at') else None,
        }
```

### 4. Web Interface Implementation

#### Import/Export Views
```python
# views/import_export_views.py
from django.shortcuts import render, get_object_or_404, redirect
from django.http import JsonResponse, HttpResponse, Http404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.core.files.storage import default_storage
from django.conf import settings
import os

from ..models import ImportExportJob
from ..services.import_service import BookImporter, ReviewImporter
from ..services.export_service import CSVExporter, JSONExporter, XMLExporter, BookExporter

@login_required
def import_export_dashboard(request):
    """Main dashboard for import/export operations."""
    recent_jobs = ImportExportJob.objects.filter(
        user=request.user
    ).order_by('-created_at')[:10]
    
    context = {
        'recent_jobs': recent_jobs,
        'supported_formats': ['csv', 'json', 'xml'],
    }
    return render(request, 'import_export/dashboard.html', context)

@login_required
def upload_import_file(request):
    """Handle file upload for import."""
    if request.method == 'POST':
        uploaded_file = request.FILES.get('file')
        import_type = request.POST.get('import_type', 'books')
        file_format = request.POST.get('format', 'csv')
        
        if not uploaded_file:
            return JsonResponse({'error': 'No file uploaded'}, status=400)
        
        # Validate file format
        if not uploaded_file.name.lower().endswith(f'.{file_format}'):
            return JsonResponse({
                'error': f'File must be in {file_format.upper()} format'
            }, status=400)
        
        # Create import job
        job = ImportExportJob.objects.create(
            job_type='import',
            format=file_format,
            user=request.user,
            file_name=uploaded_file.name,
            status='pending'
        )
        
        # Save uploaded file
        file_path = f'import_export/{job.id}_{uploaded_file.name}'
        saved_path = default_storage.save(file_path, uploaded_file)
        job.file_path = saved_path
        job.save()
        
        # Start import process (in background task or immediately)
        try:
            file_content = uploaded_file.read().decode('utf-8')
            
            # Choose appropriate importer
            if import_type == 'books':
                importer = BookImporter(job)
            elif import_type == 'reviews':
                importer = ReviewImporter(job)
            else:
                return JsonResponse({'error': 'Invalid import type'}, status=400)
            
            # Process import
            result = importer.import_data(file_content)
            
            return JsonResponse({
                'job_id': str(job.id),
                'status': job.status,
                'result': result
            })
            
        except Exception as e:
            job.status = 'failed'
            job.error_log = str(e)
            job.save()
            
            return JsonResponse({
                'error': f'Import failed: {str(e)}',
                'job_id': str(job.id)
            }, status=500)
    
    return JsonResponse({'error': 'Method not allowed'}, status=405)

@login_required
def export_data(request):
    """Handle data export requests."""
    if request.method == 'POST':
        export_type = request.POST.get('export_type', 'books')
        file_format = request.POST.get('format', 'csv')
        
        # Create export job
        job = ImportExportJob.objects.create(
            job_type='export',
            format=file_format,
            user=request.user,
            file_name=f'{export_type}_export.{file_format}',
            status='pending'
        )
        
        try:
            # Get data to export
            if export_type == 'books':
                filters = {
                    'genre_ids': request.POST.getlist('genre_ids'),
                    'author_ids': request.POST.getlist('author_ids'),
                }
                queryset = BookExporter.get_books_with_details(filters)
            else:
                return JsonResponse({'error': 'Invalid export type'}, status=400)
            
            # Choose appropriate exporter
            if file_format == 'csv':
                exporter = CSVExporter(job)
            elif file_format == 'json':
                exporter = JSONExporter(job)
            elif file_format == 'xml':
                exporter = XMLExporter(job)
            else:
                return JsonResponse({'error': 'Invalid format'}, status=400)
            
            # Generate export content
            content = exporter.export_data(queryset)
            
            # Save export file
            file_path = f'import_export/exports/{job.id}_{job.file_name}'
            saved_path = default_storage.save(file_path, content.encode('utf-8'))
            job.file_path = saved_path
            job.save()
            
            return JsonResponse({
                'job_id': str(job.id),
                'status': job.status,
                'download_url': f'/import-export/download/{job.id}/'
            })
            
        except Exception as e:
            job.status = 'failed'
            job.error_log = str(e)
            job.save()
            
            return JsonResponse({
                'error': f'Export failed: {str(e)}',
                'job_id': str(job.id)
            }, status=500)
    
    return JsonResponse({'error': 'Method not allowed'}, status=405)

@login_required
def job_status(request, job_id):
    """Get job status and progress."""
    job = get_object_or_404(ImportExportJob, id=job_id, user=request.user)
    
    response_data = {
        'id': str(job.id),
        'status': job.status,
        'job_type': job.job_type,
        'format': job.format,
        'file_name': job.file_name,
        'total_records': job.total_records,
        'processed_records': job.processed_records,
        'successful_records': job.successful_records,
        'failed_records': job.failed_records,
        'started_at': job.started_at.isoformat() if job.started_at else None,
        'completed_at': job.completed_at.isoformat() if job.completed_at else None,
        'result_summary': job.result_summary,
    }
    
    # Add progress percentage
    if job.total_records > 0:
        response_data['progress_percentage'] = (job.processed_records / job.total_records) * 100
    else:
        response_data['progress_percentage'] = 0
    
    # Add errors if any
    if job.errors.exists():
        response_data['errors'] = [
            {
                'row_number': error.row_number,
                'field_name': error.field_name,
                'error_message': error.error_message,
            }
            for error in job.errors.all()[:10]  # Limit to first 10 errors
        ]
        response_data['total_errors'] = job.errors.count()
    
    return JsonResponse(response_data)

@login_required
def download_file(request, job_id):
    """Download exported file."""
    job = get_object_or_404(ImportExportJob, id=job_id, user=request.user)
    
    if job.job_type != 'export' or job.status != 'completed':
        raise Http404("File not available for download")
    
    if not job.file_path or not default_storage.exists(job.file_path):
        raise Http404("File not found")
    
    # Determine content type
    content_types = {
        'csv': 'text/csv',
        'json': 'application/json',
        'xml': 'application/xml',
        'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    }
    
    content_type = content_types.get(job.format, 'application/octet-stream')
    
    # Read and return file
    with default_storage.open(job.file_path, 'rb') as f:
        response = HttpResponse(f.read(), content_type=content_type)
        response['Content-Disposition'] = f'attachment; filename="{job.file_name}"'
        return response

# URL patterns
from django.urls import path

urlpatterns = [
    path('import-export/', import_export_dashboard, name='import_export_dashboard'),
    path('import-export/upload/', upload_import_file, name='upload_import_file'),
    path('import-export/export/', export_data, name='export_data'),
    path('import-export/job/<uuid:job_id>/', job_status, name='job_status'),
    path('import-export/download/<uuid:job_id>/', download_file, name='download_file'),
]
```

### 5. Management Commands

#### Import/Export Management Commands
```python
# management/commands/import_books.py
from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.models import User
import os

from devtest.app.models import ImportExportJob
from devtest.app.services.import_service import BookImporter, ReviewImporter

class Command(BaseCommand):
    help = 'Import books from CSV, JSON, or XML file'
    
    def add_arguments(self, parser):
        parser.add_argument('file_path', type=str, help='Path to the import file')
        parser.add_argument('--format', type=str, choices=['csv', 'json', 'xml'], 
                          default='csv', help='File format')
        parser.add_argument('--type', type=str, choices=['books', 'reviews'], 
                          default='books', help='Import type')
        parser.add_argument('--user', type=str, help='Username for job tracking')
    
    def handle(self, *args, **options):
        file_path = options['file_path']
        file_format = options['format']
        import_type = options['type']
        username = options.get('user', 'admin')
        
        # Validate file exists
        if not os.path.exists(file_path):
            raise CommandError(f'File does not exist: {file_path}')
        
        # Get user
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            raise CommandError(f'User does not exist: {username}')
        
        # Create job
        job = ImportExportJob.objects.create(
            job_type='import',
            format=file_format,
            user=user,
            file_name=os.path.basename(file_path),
            status='pending'
        )
        
        try:
            # Read file
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Choose importer
            if import_type == 'books':
                importer = BookImporter(job)
            elif import_type == 'reviews':
                importer = ReviewImporter(job)
            else:
                raise CommandError(f'Invalid import type: {import_type}')
            
            self.stdout.write(f'Starting import of {import_type} from {file_path}...')
            
            # Process import
            result = importer.import_data(content)
            
            # Display results
            self.stdout.write(
                self.style.SUCCESS(
                    f'Import completed successfully!\n'
                    f'Total records: {result["total"]}\n'
                    f'Successful: {result["successful"]}\n'
                    f'Failed: {result["failed"]}\n'
                    f'Job ID: {job.id}'
                )
            )
            
            # Display errors if any
            if result['failed'] > 0:
                self.stdout.write(
                    self.style.WARNING(f'Errors occurred during import:')
                )
                for error in job.errors.all()[:10]:
                    self.stdout.write(
                        f'Row {error.row_number}: {error.error_message}'
                    )
                
                if job.errors.count() > 10:
                    self.stdout.write(f'... and {job.errors.count() - 10} more errors')
        
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Import failed: {str(e)}')
            )
            raise CommandError(f'Import failed: {str(e)}')

# management/commands/export_books.py
from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.models import User
import os

from devtest.app.models import ImportExportJob, Book
from devtest.app.services.export_service import CSVExporter, JSONExporter, XMLExporter

class Command(BaseCommand):
    help = 'Export books to CSV, JSON, or XML file'
    
    def add_arguments(self, parser):
        parser.add_argument('output_path', type=str, help='Output file path')
        parser.add_argument('--format', type=str, choices=['csv', 'json', 'xml'], 
                          default='csv', help='Export format')
        parser.add_argument('--user', type=str, help='Username for job tracking')
        parser.add_argument('--genre', type=str, action='append', 
                          help='Filter by genre name (can be used multiple times)')
        parser.add_argument('--author', type=str, action='append',
                          help='Filter by author name (can be used multiple times)')
    
    def handle(self, *args, **options):
        output_path = options['output_path']
        file_format = options['format']
        username = options.get('user', 'admin')
        
        # Get user
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            raise CommandError(f'User does not exist: {username}')
        
        # Create job
        job = ImportExportJob.objects.create(
            job_type='export',
            format=file_format,
            user=user,
            file_name=os.path.basename(output_path),
            status='pending'
        )
        
        try:
            # Build queryset with filters
            queryset = Book.objects.select_related('author').prefetch_related('genres')
            
            if options.get('genre'):
                queryset = queryset.filter(genres__name__in=options['genre'])
            
            if options.get('author'):
                queryset = queryset.filter(author__name__in=options['author'])
            
            queryset = queryset.distinct()
            
            # Choose exporter
            if file_format == 'csv':
                exporter = CSVExporter(job)
            elif file_format == 'json':
                exporter = JSONExporter(job)
            elif file_format == 'xml':
                exporter = XMLExporter(job)
            else:
                raise CommandError(f'Invalid format: {file_format}')
            
            self.stdout.write(f'Starting export to {output_path}...')
            
            # Generate export content
            content = exporter.export_data(queryset)
            
            # Write to file
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            self.stdout.write(
                self.style.SUCCESS(
                    f'Export completed successfully!\n'
                    f'Records exported: {job.processed_records}\n'
                    f'Output file: {output_path}\n'
                    f'Job ID: {job.id}'
                )
            )
        
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Export failed: {str(e)}')
            )
            raise CommandError(f'Export failed: {str(e)}')
```

### 6. Frontend Templates

#### Import/Export Dashboard
```html
<!-- templates/import_export/dashboard.html -->
{% extends 'base.html' %}

{% block title %}Import/Export Dashboard{% endblock %}

{% block content %}
<div class="container mt-4">
    <h1>Import/Export Dashboard</h1>
    
    <!-- Import Section -->
    <div class="row mt-4">
        <div class="col-md-6">
            <div class="card">
                <div class="card-header">
                    <h3>Import Data</h3>
                </div>
                <div class="card-body">
                    <form id="import-form" enctype="multipart/form-data">
                        {% csrf_token %}
                        
                        <div class="form-group">
                            <label for="import-type">Import Type:</label>
                            <select id="import-type" name="import_type" class="form-control">
                                <option value="books">Books</option>
                                <option value="reviews">Reviews</option>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label for="import-format">File Format:</label>
                            <select id="import-format" name="format" class="form-control">
                                <option value="csv">CSV</option>
                                <option value="json">JSON</option>
                                <option value="xml">XML</option>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label for="import-file">Select File:</label>
                            <div class="custom-file">
                                <input type="file" class="custom-file-input" id="import-file" name="file" required>
                                <label class="custom-file-label" for="import-file">Choose file...</label>
                            </div>
                        </div>
                        
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-upload"></i> Import Data
                        </button>
                    </form>
                    
                    <!-- Import Progress -->
                    <div id="import-progress" class="mt-3" style="display: none;">
                        <div class="progress">
                            <div id="import-progress-bar" class="progress-bar" role="progressbar" 
                                 style="width: 0%" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100">
                                0%
                            </div>
                        </div>
                        <div id="import-status" class="mt-2"></div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Export Section -->
        <div class="col-md-6">
            <div class="card">
                <div class="card-header">
                    <h3>Export Data</h3>
                </div>
                <div class="card-body">
                    <form id="export-form">
                        {% csrf_token %}
                        
                        <div class="form-group">
                            <label for="export-type">Export Type:</label>
                            <select id="export-type" name="export_type" class="form-control">
                                <option value="books">Books</option>
                                <option value="authors">Authors</option>
                                <option value="reviews">Reviews</option>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label for="export-format">File Format:</label>
                            <select id="export-format" name="format" class="form-control">
                                <option value="csv">CSV</option>
                                <option value="json">JSON</option>
                                <option value="xml">XML</option>
                            </select>
                        </div>
                        
                        <!-- Export Filters -->
                        <div class="form-group">
                            <label>Filters (Optional):</label>
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="include-reviews">
                                <label class="form-check-label" for="include-reviews">
                                    Include Reviews
                                </label>
                            </div>
                        </div>
                        
                        <button type="submit" class="btn btn-success">
                            <i class="fas fa-download"></i> Export Data
                        </button>
                    </form>
                    
                    <!-- Export Progress -->
                    <div id="export-progress" class="mt-3" style="display: none;">
                        <div class="progress">
                            <div id="export-progress-bar" class="progress-bar bg-success" role="progressbar" 
                                 style="width: 0%" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100">
                                0%
                            </div>
                        </div>
                        <div id="export-status" class="mt-2"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Recent Jobs -->
    <div class="row mt-4">
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h3>Recent Jobs</h3>
                </div>
                <div class="card-body">
                    {% if recent_jobs %}
                        <div class="table-responsive">
                            <table class="table table-striped">
                                <thead>
                                    <tr>
                                        <th>Type</th>
                                        <th>Format</th>
                                        <th>File Name</th>
                                        <th>Status</th>
                                        <th>Records</th>
                                        <th>Created</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for job in recent_jobs %}
                                        <tr>
                                            <td>
                                                <span class="badge badge-{% if job.job_type == 'import' %}primary{% else %}success{% endif %}">
                                                    {{ job.get_job_type_display }}
                                                </span>
                                            </td>
                                            <td>{{ job.format|upper }}</td>
                                            <td>{{ job.file_name }}</td>
                                            <td>
                                                <span class="badge badge-{% if job.status == 'completed' %}success{% elif job.status == 'failed' %}danger{% elif job.status == 'processing' %}warning{% else %}secondary{% endif %}">
                                                    {{ job.get_status_display }}
                                                </span>
                                            </td>
                                            <td>
                                                {% if job.total_records > 0 %}
                                                    {{ job.successful_records }}/{{ job.total_records }}
                                                    {% if job.failed_records > 0 %}
                                                        <small class="text-danger">({{ job.failed_records }} failed)</small>
                                                    {% endif %}
                                                {% else %}
                                                    -
                                                {% endif %}
                                            </td>
                                            <td>{{ job.created_at|date:"M d, Y H:i" }}</td>
                                            <td>
                                                <button class="btn btn-sm btn-info" onclick="viewJobDetails('{{ job.id }}')">
                                                    <i class="fas fa-eye"></i>
                                                </button>
                                                {% if job.job_type == 'export' and job.status == 'completed' %}
                                                    <a href="{% url 'download_file' job.id %}" class="btn btn-sm btn-success">
                                                        <i class="fas fa-download"></i>
                                                    </a>
                                                {% endif %}
                                            </td>
                                        </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                    {% else %}
                        <p class="text-muted">No recent jobs found.</p>
                    {% endif %}
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Job Details Modal -->
<div class="modal fade" id="job-details-modal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Job Details</h5>
                <button type="button" class="close" data-dismiss="modal">
                    <span>&times;</span>
                </button>
            </div>
            <div class="modal-body" id="job-details-content">
                <!-- Job details will be loaded here -->
            </div>
        </div>
    </div>
</div>

<script>
// Import/Export JavaScript functionality
class ImportExportManager {
    constructor() {
        this.init();
    }
    
    init() {
        this.bindEvents();
    }
    
    bindEvents() {
        // Import form
        document.getElementById('import-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleImport();
        });
        
        // Export form
        document.getElementById('export-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleExport();
        });
        
        // File input label update
        document.getElementById('import-file').addEventListener('change', (e) => {
            const fileName = e.target.files[0]?.name || 'Choose file...';
            document.querySelector('.custom-file-label').textContent = fileName;
        });
    }
    
    async handleImport() {
        const form = document.getElementById('import-form');
        const formData = new FormData(form);
        const progressDiv = document.getElementById('import-progress');
        const progressBar = document.getElementById('import-progress-bar');
        const statusDiv = document.getElementById('import-status');
        
        // Show progress
        progressDiv.style.display = 'block';
        statusDiv.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Starting import...';
        
        try {
            const response = await fetch('{% url "upload_import_file" %}', {
                method: 'POST',
                body: formData,
                headers: {
                    'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]').value
                }
            });
            
            const data = await response.json();
            
            if (response.ok) {
                // Poll for job status
                this.pollJobStatus(data.job_id, 'import');
            } else {
                statusDiv.innerHTML = `<div class="alert alert-danger">${data.error}</div>`;
            }
        } catch (error) {
            statusDiv.innerHTML = `<div class="alert alert-danger">Import failed: ${error.message}</div>`;
        }
    }
    
    async handleExport() {
        const form = document.getElementById('export-form');
        const formData = new FormData(form);
        const progressDiv = document.getElementById('export-progress');
        const progressBar = document.getElementById('export-progress-bar');
        const statusDiv = document.getElementById('export-status');
        
        // Show progress
        progressDiv.style.display = 'block';
        statusDiv.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Starting export...';
        
        try {
            const response = await fetch('{% url "export_data" %}', {
                method: 'POST',
                body: formData,
                headers: {
                    'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]').value
                }
            });
            
            const data = await response.json();
            
            if (response.ok) {
                // Poll for job status
                this.pollJobStatus(data.job_id, 'export');
            } else {
                statusDiv.innerHTML = `<div class="alert alert-danger">${data.error}</div>`;
            }
        } catch (error) {
            statusDiv.innerHTML = `<div class="alert alert-danger">Export failed: ${error.message}</div>`;
        }
    }
    
    async pollJobStatus(jobId, jobType) {
        const progressBar = document.getElementById(`${jobType}-progress-bar`);
        const statusDiv = document.getElementById(`${jobType}-status`);
        
        const poll = async () => {
            try {
                const response = await fetch(`/import-export/job/${jobId}/`);
                const data = await response.json();
                
                // Update progress bar
                const percentage = data.progress_percentage || 0;
                progressBar.style.width = `${percentage}%`;
                progressBar.textContent = `${Math.round(percentage)}%`;
                
                // Update status
                if (data.status === 'processing') {
                    statusDiv.innerHTML = `
                        <div class="alert alert-info">
                            Processing... ${data.processed_records}/${data.total_records} records
                        </div>
                    `;
                    setTimeout(poll, 1000); // Poll every second
                } else if (data.status === 'completed') {
                    statusDiv.innerHTML = `
                        <div class="alert alert-success">
                            ${jobType === 'import' ? 'Import' : 'Export'} completed successfully!<br>
                            Processed: ${data.successful_records}/${data.total_records} records
                            ${data.failed_records > 0 ? `<br>Failed: ${data.failed_records} records` : ''}
                            ${data.download_url ? `<br><a href="${data.download_url}" class="btn btn-sm btn-success mt-2"><i class="fas fa-download"></i> Download</a>` : ''}
                        </div>
                    `;
                } else if (data.status === 'failed') {
                    statusDiv.innerHTML = `
                        <div class="alert alert-danger">
                            ${jobType === 'import' ? 'Import' : 'Export'} failed!
                        </div>
                    `;
                }
            } catch (error) {
                statusDiv.innerHTML = `
                    <div class="alert alert-danger">
                        Error checking job status: ${error.message}
                    </div>
                `;
            }
        };
        
        poll();
    }
}

// Job details function
async function viewJobDetails(jobId) {
    try {
        const response = await fetch(`/import-export/job/${jobId}/`);
        const data = await response.json();
        
        let content = `
            <div class="row">
                <div class="col-md-6">
                    <h6>Job Information</h6>
                    <p><strong>Type:</strong> ${data.job_type}</p>
                    <p><strong>Format:</strong> ${data.format}</p>
                    <p><strong>Status:</strong> <span class="badge badge-info">${data.status}</span></p>
                    <p><strong>File:</strong> ${data.file_name}</p>
                </div>
                <div class="col-md-6">
                    <h6>Progress</h6>
                    <p><strong>Total Records:</strong> ${data.total_records}</p>
                    <p><strong>Processed:</strong> ${data.processed_records}</p>
                    <p><strong>Successful:</strong> ${data.successful_records}</p>
                    <p><strong>Failed:</strong> ${data.failed_records}</p>
                </div>
            </div>
        `;
        
        if (data.errors && data.errors.length > 0) {
            content += `
                <div class="mt-3">
                    <h6>Errors</h6>
                    <div class="table-responsive">
                        <table class="table table-sm">
                            <thead>
                                <tr>
                                    <th>Row</th>
                                    <th>Field</th>
                                    <th>Error</th>
                                </tr>
                            </thead>
                            <tbody>
            `;
            
            data.errors.forEach(error => {
                content += `
                    <tr>
                        <td>${error.row_number}</td>
                        <td>${error.field_name || '-'}</td>
                        <td>${error.error_message}</td>
                    </tr>
                `;
            });
            
            content += `
                            </tbody>
                        </table>
                    </div>
                    ${data.total_errors > 10 ? `<p class="text-muted">Showing first 10 of ${data.total_errors} errors</p>` : ''}
                </div>
            `;
        }
        
        document.getElementById('job-details-content').innerHTML = content;
        $('#job-details-modal').modal('show');
        
    } catch (error) {
        alert('Error loading job details: ' + error.message);
    }
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    new ImportExportManager();
});
</script>
{% endblock %}
```

## Evaluation Criteria

### Data Processing (30%)
- Accurate data parsing and validation
- Proper error handling and reporting
- Support for multiple file formats
- Efficient processing of large files

### System Integration (25%)
- Clean integration with existing models
- Proper transaction handling
- Database optimization
- Background job processing

### User Experience (20%)
- Intuitive web interface
- Progress tracking and feedback
- Error reporting and recovery
- File download functionality

### Code Quality (15%)
- Clean, maintainable code
- Proper error handling
- Documentation and comments
- Testing coverage

### Advanced Features (10%)
- Management command implementation
- Data validation and transformation
- Performance optimization
- Extensibility and flexibility

## Submission Guidelines

### What to Submit
1. **Import/Export Models**: Job tracking and error models
2. **Service Classes**: Import and export service implementations
3. **Web Interface**: Views, templates, and JavaScript
4. **Management Commands**: CLI tools for import/export
5. **Sample Data Files**: Example CSV, JSON, and XML files
6. **Documentation**: Usage guide and API documentation

### Testing Data
Include sample files for testing:
- `sample_books.csv` - Sample book data
- `sample_reviews.json` - Sample review data
- `sample_data.xml` - Mixed data format

## Helpful Resources

- **Django File Handling**: https://docs.djangoproject.com/en/stable/topics/files/
- **CSV Processing**: https://docs.python.org/3/library/csv.html
- **JSON Processing**: https://docs.python.org/3/library/json.html
- **XML Processing**: https://docs.python.org/3/library/xml.etree.elementtree.html

## Time Management Tips

- **Hour 1**: Implement basic import/export models and services
- **Hour 2**: Create web interface and file handling
- **Hour 3**: Add management commands and error handling

## Common Pitfalls to Avoid

- Not validating file formats and data
- Missing error handling for large files
- Not providing progress feedback
- Ignoring memory usage with large datasets
- Not handling duplicate data properly
- Missing transaction management
- Poor error reporting to users

Good luck building your import/export system! Focus on creating a robust, user-friendly system that can handle real-world data processing scenarios.
