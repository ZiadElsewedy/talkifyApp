import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/WhiteCircleIndicator.dart';

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
      // Check file extension
      final fileExtension = _getFileExtension(widget.fileName).toLowerCase();
      _isPdf = fileExtension == 'pdf';
      
      // If not PDF, open in external app
      if (!_isPdf) {
        _openInExternalApp(widget.documentUrl);
        return;
      }
      
      // Download the file
      final response = await http.get(Uri.parse(widget.documentUrl));
      
      if (response.statusCode == 200) {
        // Get temp directory
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/${widget.fileName}';
        
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
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to download document: HTTP ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading document: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  String _getFileExtension(String fileName) {
    return fileName.contains('.') ? fileName.split('.').last : '';
  }
  
  Future<void> _openInExternalApp(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Go back after launching external app
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Could not open this file type. No app available to handle it.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error opening document: $e';
          _isLoading = false;
        });
      }
    }
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (!_isLoading && _localFilePath != null && _isPdf)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Share functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openInExternalApp(widget.documentUrl),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load document',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _openInExternalApp(widget.documentUrl),
                child: const Text('Open in External App'),
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
          setState(() {
            _totalPages = pages!;
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = error.toString();
          });
        },
        onPageError: (page, error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading page $page: $error')),
          );
        },
        onPageChanged: (page, _) {
          setState(() {
            _currentPage = page!;
          });
        },
      );
    }

    // Fallback
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'This document type cannot be previewed',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _openInExternalApp(widget.documentUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open in External App'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (!_isLoading && _localFilePath != null && _isPdf && _totalPages > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Page ${_currentPage + 1} of $_totalPages',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
} 