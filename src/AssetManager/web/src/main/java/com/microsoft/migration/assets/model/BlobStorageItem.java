package com.microsoft.migration.assets.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BlobStorageItem {
    private String name;
    private String displayName;
    private long size;
    private Instant lastModified;
    private Instant uploadedAt;
    private String url;
}