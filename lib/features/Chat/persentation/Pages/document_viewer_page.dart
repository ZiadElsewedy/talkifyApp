import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class DocumentViewerPage extends StatefulWidget {
  final String documentUrl;
  final String fileName;

  const DocumentViewerPage({
    super.key,
    required this.documentUrl,
    required this.fileName,
  });

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _localFilePath;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isPdf = false;
  double _downloadProgress = 0.0;
  int _downloadRetries = 0;
  final int _maxRetries = 3;
  
  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print("Loading document: ${widget.fileName}, URL: ${widget.documentUrl}");
      
      // Check file extension
      final fileExtension = _getFileExtension(widget.fileName).toLowerCase();
      _isPdf = fileExtension == 'pdf';
      
      print("Document file extension: $fileExtension, isPdf: $_isPdf");
      
      // Clean up URL (remove any query parameters)
      String cleanUrl = widget.documentUrl;
      if (cleanUrl.contains('?')) {
        cleanUrl = cleanUrl.split('?')[0];
      }
      
      // Always try to download the file first
      bool downloadSuccess = false;
      try {
        // Download the file with retry mechanism
        await _downloadWithRetry(cleanUrl);
        downloadSuccess = _localFilePath != null;
        print("Document download ${downloadSuccess ? 'successful' : 'failed'}: $_localFilePath");
      } catch (e) {
        print("Error downloading document: $e");
        downloadSuccess = false;
      }
      
      // If download failed or for non-PDF files, try external app
      if (!downloadSuccess || !_isPdf) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Show option to open in external app for non-PDFs
          if (!_isPdf) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('This document type works better in external apps'),
                action: SnackBarAction(
                  label: 'OPEN',
                  onPressed: () => _openInExternalApp(widget.documentUrl),
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
          
          // For failed downloads, try external app immediately
          if (!downloadSuccess) {
            await Future.delayed(Duration(milliseconds: 500));
            _openInExternalApp(widget.documentUrl);
          }
        }
      }
      
    } catch (e) {
      print("Error loading document: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading document: $e';
          _isLoading = false;
        });
        
        // If there's an error, still try external app
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing document internally. Try external app.'),
            action: SnackBarAction(
              label: 'OPEN',
              onPressed: () => _openInExternalApp(widget.documentUrl),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  Future<void> _downloadWithRetry(String url) async {
    while (_downloadRetries < _maxRetries) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Connection timed out');
          },
        );
        
        if (response.statusCode == 200) {
          // Get temp directory
          final dir = await getTemporaryDirectory();
          
          // Create a safe filename
          final safeName = widget.fileName.replaceAll(RegExp(r'[^\w\s\.\-]'), '_');
          final filePath = '${dir.path}/$safeName';
          
          // Save file
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          
          if (mounted) {
            setState(() {
              _localFilePath = filePath;
              _isLoading = false;
            });
          }
          return; // Success
        } else {
          // Increment retry counter
          _downloadRetries++;
          if (_downloadRetries >= _maxRetries || !mounted) {
            setState(() {
              _errorMessage = 'Failed to download document: HTTP ${response.statusCode}';
              _isLoading = false;
            });
            return;
          }
          
          // Wait before retrying
          await Future.delayed(Duration(seconds: 2));
        }
      } catch (e) {
        // Increment retry counter
        _downloadRetries++;
        if (_downloadRetries >= _maxRetries || !mounted) {
          setState(() {
            _errorMessage = 'Error downloading document: $e';
            _isLoading = false;
          });
          return;
        }
        
        // Wait before retrying
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }
  
  String _getFileExtension(String fileName) {
    return fileName.contains('.') ? fileName.split('.').last : '';
  }
  
  Future<void> _openInExternalApp(String url) async {
    try {
      print("Attempting to open URL in external app: $url");
      final uri = Uri.parse(url);
      
      // First try to open in external application mode
      bool launched = false;
      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print("Error opening in external application mode: $e");
      }
      
      // If that failed, try to open in external non-browser app
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
        } catch (e) {
          print("Error opening in external non-browser mode: $e");
        }
      }
      
      // If that failed too, try platform default
      if (!launched) {
        launched = await launchUrl(uri);
      }
      
      // Go back after launching external app if successful
      if (mounted && launched) {
        Navigator.pop(context);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Could not open this file. Try downloading it instead.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error opening document: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Error opening document: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _downloadDocument() async {
    if (_isDownloading) return;
    
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });
    
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Storage permission is required to download files';
        });
        return;
      }
      
      // Create a safe filename by removing special characters
      final safeFileName = widget.fileName.replaceAll(RegExp(r'[^\w\s\.\-]'), '_');
      
      // Get download directory
      Directory? directory;
      
      try {
        // Try to get the downloads directory first
        directory = await getDownloadsDirectory();
      } catch (e) {
        print('Could not get downloads directory: $e');
      }
      
      // If downloads directory is not available, try external storage
      if (directory == null) {
        try {
          directory = await getExternalStorageDirectory();
        } catch (e) {
          print('Could not get external storage directory: $e');
        }
      }
      
      // If both failed, use app documents directory
      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Could not find a download directory';
        });
        return;
      }
      
      final savePath = path.join(directory.path, safeFileName);
      final file = File(savePath);
      
      // Download with progress tracking
      final request = http.Request('GET', Uri.parse(widget.documentUrl));
      final response = await http.Client().send(request);
      
      final contentLength = response.contentLength ?? 0;
      int bytesReceived = 0;
      
      final sink = file.openWrite();
      
      await response.stream.listen((List<int> chunk) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        
        if (contentLength > 0 && mounted) {
          setState(() {
            _downloadProgress = bytesReceived / contentLength;
          });
        }
      }).asFuture();
      
      await sink.close();
      
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 1.0;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document downloaded to:\n${directory.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () {
                final uri = Uri.file(savePath);
                launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Error downloading document: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: isDarkMode ? colorScheme.surface : Colors.white,
        foregroundColor: isDarkMode ? colorScheme.onSurface : Colors.black,
        elevation: 1,
        actions: [
          if (!_isLoading && _localFilePath != null)
            IconButton(
              icon: _isDownloading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(isDarkMode ? Colors.white : Colors.black),
                    ),
                  )
                : Icon(Icons.download),
              onPressed: _isDownloading ? null : _downloadDocument,
              tooltip: 'Download document',
            ),
          IconButton(
            icon: Icon(Icons.open_in_new),
            onPressed: () => _openInExternalApp(widget.documentUrl),
            tooltip: 'Open in external app',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _isPdf ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PercentCircleIndicator(),
            SizedBox(height: 16),
            Text('Loading document...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final ColorScheme colorScheme = Theme.of(context).colorScheme;
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load document',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? colorScheme.onSurface : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? colorScheme.onSurfaceVariant : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _openInExternalApp(widget.documentUrl),
                child: Text('Open in External App', 
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_localFilePath != null && _isPdf) {
      return PDFView(
        filePath: _localFilePath!,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        defaultPage: _currentPage,
        onRender: (pages) {
          if (mounted) {
            setState(() {
              _totalPages = pages ?? 0;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = error.toString();
            });
          }
        },
        onPageError: (page, error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading page $page: $error')),
            );
          }
        },
        onPageChanged: (page, _) {
          if (mounted) {
            setState(() {
              _currentPage = page ?? 0;
            });
          }
        },
      );
    }

    // Fallback for non-PDF files
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 64,
            color: isDarkMode ? colorScheme.onSurfaceVariant : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'This document type cannot be previewed',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? colorScheme.onSurface : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _openInExternalApp(widget.documentUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Open in External App'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _downloadDocument,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
            ),
            child: const Text('Download Document'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (!_isPdf || _totalPages == 0 || _localFilePath == null) {
      return SizedBox.shrink();
    }
    
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: 50,
      color: isDarkMode ? colorScheme.primary : Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_left, color: Colors.white),
            onPressed: _currentPage > 0 
                ? () => _jumpToPage(_currentPage - 1) 
                : null,
            disabledColor: Colors.white.withOpacity(0.3),
          ),
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: TextStyle(color: Colors.white),
          ),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_right, color: Colors.white),
            onPressed: _currentPage < _totalPages - 1 
                ? () => _jumpToPage(_currentPage + 1) 
                : null,
            disabledColor: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
  
  void _jumpToPage(int page) {
    PDFView(
      filePath: _localFilePath!,
      defaultPage: page,
    );
    setState(() {
      _currentPage = page;
    });
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() {
    return message;
  }
} 