package com.microsoft.migration.assets.worker.service;

import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.microsoft.migration.assets.worker.repository.ImageMetadataRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

@Service
@Profile("!dev")
@RequiredArgsConstructor
public class AzureBlobFileProcessingService extends AbstractFileProcessingService {
    private final BlobServiceClient blobServiceClient;
    private final ImageMetadataRepository imageMetadataRepository;
    
    @Value("${azure.storage.container-name}")
    private String containerName;

    @Override
    public void downloadOriginal(String blobName, Path destination) throws Exception {
        BlobContainerClient containerClient = blobServiceClient.getBlobContainerClient(containerName);
        BlobClient blobClient = containerClient.getBlobClient(blobName);
                
        try (InputStream inputStream = blobClient.openInputStream()) {
            Files.copy(inputStream, destination, StandardCopyOption.REPLACE_EXISTING);
        }
    }

    @Override
    public void uploadThumbnail(Path source, String blobName, String contentType) throws Exception {
        BlobContainerClient containerClient = blobServiceClient.getBlobContainerClient(containerName);
        BlobClient blobClient = containerClient.getBlobClient(blobName);
                
        blobClient.uploadFromFile(source.toString(), true);
        blobClient.setHttpHeaders(new com.azure.storage.blob.models.BlobHttpHeaders()
                .setContentType(contentType));

        // Extract the original key from the thumbnail key
        String originalBlobName = extractOriginalKey(blobName);
        
        // Find and update metadata
        imageMetadataRepository.findAll().stream()
            .filter(metadata -> metadata.getBlobName().equals(originalBlobName))
            .findFirst()
            .ifPresent(metadata -> {
                metadata.setThumbnailBlobName(blobName);
                metadata.setThumbnailUrl(generateUrl(blobName));
                imageMetadataRepository.save(metadata);
            });
    }

    @Override
    public String getStorageType() {
        return "azure";
    }

    @Override
    protected String generateUrl(String blobName) {
        BlobContainerClient containerClient = blobServiceClient.getBlobContainerClient(containerName);
        BlobClient blobClient = containerClient.getBlobClient(blobName);
        return blobClient.getBlobUrl();
    }

    private String extractOriginalKey(String key) {
        // For a key like "xxxxx_thumbnail.png", get "xxxxx.png"
        String suffix = "_thumbnail";
        int extensionIndex = key.lastIndexOf('.');
        if (extensionIndex > 0) {
            String nameWithoutExtension = key.substring(0, extensionIndex);
            String extension = key.substring(extensionIndex);
            
            int suffixIndex = nameWithoutExtension.lastIndexOf(suffix);
            if (suffixIndex > 0) {
                return nameWithoutExtension.substring(0, suffixIndex) + extension;
            }
        }
        return key;
    }
}