import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

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
  String? _localFilePath;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isPdf = false;
  
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
      
      // Skip internal viewer for non-PDF files
      if (!_isPdf) {
        // Just open non-PDF files directly in external app
        _openInExternalApp(widget.documentUrl);
        return;
      }
      
      // For PDF files, download and open internally
      try {
        // Clean up URL
      String cleanUrl = widget.documentUrl;
      if (cleanUrl.contains('?')) {
        cleanUrl = cleanUrl.split('?')[0];
      }
      
        // Download with simplified error handling
        final response = await http.get(Uri.parse(cleanUrl)).timeout(
          const Duration(seconds: 30),
        );
        
        if (response.statusCode == 200) {
          // Get temp directory
          final dir = await getTemporaryDirectory();
          
          // Create a safe filename with timestamp
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final safeName = "${timestamp}_${widget.fileName.replaceAll(RegExp(r'[^\w\s\.\-]'), '_')}";
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
        } else {
          // Handle HTTP error
          throw Exception('Failed to download: HTTP ${response.statusCode}');
        }
      } catch (e) {
        print("Error downloading PDF: $e");
        // If download fails, try external app
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Could not load PDF internally';
          });
          
          // Show option to open externally
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening document in external app...'),
              duration: Duration(seconds: 2),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
          _openInExternalApp(widget.documentUrl);
        }
      }
    } catch (e) {
      print("Error in _loadDocument: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading document';
          _isLoading = false;
        });
        
        // Try external app as last resort
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening in external app instead'),
            duration: Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        _openInExternalApp(widget.documentUrl);
      }
    }
  }
  
  String _getFileExtension(String fileName) {
    return fileName.contains('.') ? fileName.split('.').last : '';
  }
  
  Future<void> _openInExternalApp(String url) async {
    try {
      print("Opening document in external app: $url");
      
      // Show a loading indicator
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 20, height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 16),
                Text("Opening document externally..."),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Download the file to a temporary location first, then open it
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = "${timestamp}_${widget.fileName}";
      final filePath = "${tempDir.path}/$fileName";
      final file = File(filePath);
      
      // Download file
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          
          // Now try to open the local file
          final fileUri = Uri.file(filePath);
          
          bool success = false;
          
          // Try various launch modes
          try {
            if (await canLaunchUrl(fileUri)) {
              success = await launchUrl(fileUri, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            print("Failed to open with external app: $e");
          }
          
          if (!success) {
            try {
              success = await launchUrl(Uri.parse(url), mode: LaunchMode.externalNonBrowserApplication);
            } catch (e) {
              print("Failed to open with non-browser: $e");
            }
          }
          
          if (!success) {
            try {
              success = await launchUrl(Uri.parse(url));
            } catch (e) {
              print("Failed to open with default: $e");
            }
          }
          
          // If successfully launched, close the viewer
          if (success && mounted) {
          Navigator.pop(context);
          } else if (mounted) {
            _showDownloadOnlyOption(url);
          }
        } else {
          throw Exception("HTTP error: ${response.statusCode}");
        }
      } catch (e) {
        print("Error handling document: $e");
        
        // As a last resort, try to open the URL directly
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          if (mounted) Navigator.pop(context);
        } else if (mounted) {
          _showDownloadOnlyOption(url);
        }
      }
    } catch (e) {
      print("Error in _openInExternalApp: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't open the document"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDownloadOnlyOption(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Can't Open Document"),
        content: const Text("Would you like to download this document instead?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadDocument();
            },
            child: const Text("DOWNLOAD"),
          ),
        ],
      ),
    );
  }
  
  Future<void> _downloadDocument() async {
    try {
      final status = await Permission.storage.request();
      
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission required to download files')),
          );
        }
        return;
      }
      
      // Use external app for download
      final uri = Uri.parse(widget.documentUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      
    } catch (e) {
      print("Error downloading document: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading document: $e')),
        );
      }
    }
  }
  
  void _jumpToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
            IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _downloadDocument,
            tooltip: 'Download',
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openInExternalApp(widget.documentUrl),
            tooltip: 'Open in external app',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
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
      
      return Container(
        color: isDarkMode ? const Color(0xFF121212) : Colors.white,
        child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                  color: isDarkMode ? Colors.redAccent : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load document',
                style: TextStyle(
                    fontSize: 20,
                  fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
              Text(
                  'This file cannot be previewed in the app',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _openInExternalApp(widget.documentUrl),
                style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.blueAccent : colorScheme.primary,
                  foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: isDarkMode ? 2 : 4,
                ),
                    child: const Text(
                      'Open in External App',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
              ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _loadDocument,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try Again'),
                  style: TextButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.lightBlueAccent : colorScheme.primary,
                  ),
              ),
            ],
            ),
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
    
    return Container(
      color: isDarkMode ? const Color(0xFF121212) : Colors.white,
      child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 64,
              color: isDarkMode ? Colors.blueGrey[300] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'This document type cannot be previewed',
            style: TextStyle(
              fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
            onPressed: () => _openInExternalApp(widget.documentUrl),
            style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.blueAccent : colorScheme.primary,
              foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
            ),
            child: const Text('Open in External App'),
              ),
          ),
          const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: ElevatedButton(
            onPressed: _downloadDocument,
            style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.grey[800] : colorScheme.secondary,
                  foregroundColor: isDarkMode ? Colors.white : colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
            ),
            child: const Text('Download Document'),
              ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (!_isPdf || _totalPages == 0 || _localFilePath == null) {
      return const SizedBox.shrink();
    }
    
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: 50,
      color: isDarkMode ? const Color(0xFF101010) : Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white),
            onPressed: _currentPage > 0 
                ? () => _jumpToPage(_currentPage - 1) 
                : null,
            disabledColor: Colors.white.withOpacity(0.3),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blueAccent.withOpacity(0.3) : Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
          ),
            child: Text(
            'Page ${_currentPage + 1} of $_totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_right, color: Colors.white),
            onPressed: _currentPage < _totalPages - 1 
                ? () => _jumpToPage(_currentPage + 1) 
                : null,
            disabledColor: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
} 