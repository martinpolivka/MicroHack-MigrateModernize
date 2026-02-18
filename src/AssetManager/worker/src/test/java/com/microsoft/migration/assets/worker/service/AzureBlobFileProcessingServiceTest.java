package com.microsoft.migration.assets.worker.service;

import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.microsoft.migration.assets.worker.repository.ImageMetadataRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.ByteArrayInputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AzureBlobFileProcessingServiceTest {

    @Mock
    private BlobServiceClient blobServiceClient;

    @Mock
    private BlobContainerClient blobContainerClient;

    @Mock
    private BlobClient blobClient;

    @Mock
    private ImageMetadataRepository imageMetadataRepository;

    @InjectMocks
    private AzureBlobFileProcessingService azureBlobFileProcessingService;

    private final String containerName = "test-container";
    private final String testBlobName = "test-image.jpg";
    private final String thumbnailBlobName = "test-image_thumbnail.jpg";

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(azureBlobFileProcessingService, "containerName", containerName);
    }

    @Test
    void getStorageTypeReturnsAzure() {
        // Act
        String result = azureBlobFileProcessingService.getStorageType();

        // Assert
        assertEquals("azure", result);
    }

    @Test
    void downloadOriginalCopiesFileFromBlob() throws Exception {
        // Arrange
        Path tempFile = Files.createTempFile("download-", ".tmp");
        
        // Create a mock BlobInputStream
        com.azure.storage.blob.specialized.BlobInputStream mockBlobInputStream = 
            mock(com.azure.storage.blob.specialized.BlobInputStream.class);

        when(blobServiceClient.getBlobContainerClient(containerName)).thenReturn(blobContainerClient);
        when(blobContainerClient.getBlobClient(testBlobName)).thenReturn(blobClient);
        when(blobClient.openInputStream()).thenReturn(mockBlobInputStream);
        
        // Mock read behavior
        when(mockBlobInputStream.read(any(byte[].class))).thenReturn(-1); // EOF

        // Act
        azureBlobFileProcessingService.downloadOriginal(testBlobName, tempFile);

        // Assert
        verify(blobServiceClient).getBlobContainerClient(containerName);
        verify(blobContainerClient).getBlobClient(testBlobName);
        verify(blobClient).openInputStream();

        // Clean up
        Files.deleteIfExists(tempFile);
    }

    @Test
    void uploadThumbnailPutsFileToBlob() throws Exception {
        // Arrange
        Path tempFile = Files.createTempFile("thumbnail-", ".tmp");
        when(blobServiceClient.getBlobContainerClient(containerName)).thenReturn(blobContainerClient);
        when(blobContainerClient.getBlobClient(thumbnailBlobName)).thenReturn(blobClient);
        when(imageMetadataRepository.findAll()).thenReturn(Collections.emptyList());

        // Act
        azureBlobFileProcessingService.uploadThumbnail(tempFile, thumbnailBlobName, "image/jpeg");

        // Assert
        verify(blobServiceClient).getBlobContainerClient(containerName);
        verify(blobContainerClient).getBlobClient(thumbnailBlobName);
        verify(blobClient).uploadFromFile(tempFile.toString(), true);

        // Clean up
        Files.deleteIfExists(tempFile);
    }

    @Test
    void testExtractOriginalKey() throws Exception {
        // Use reflection to test private method
        String result = (String) ReflectionTestUtils.invokeMethod(
                azureBlobFileProcessingService,
                "extractOriginalKey",
                "image_thumbnail.jpg");

        // Assert
        assertEquals("image.jpg", result);
    }
}
