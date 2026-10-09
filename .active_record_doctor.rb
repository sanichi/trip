ActiveRecordDoctor.configure do
  # Global settings affect all detectors.
  global :ignore_tables, [
    # Ignore internal Rails-related tables.
    "ar_internal_metadata",
    "schema_migrations",
    "active_storage_blobs",
    "active_storage_attachments",
    "active_storage_variant_records",
    "action_text_rich_texts",

    # Add project-specific tables here.
  ]

  # Detector-specific settings affect only one specific detector.

  # Model-based detectors don't honor ignore_tables, so exclude the Active Storage models by name.
  detector :missing_presence_validation,
    ignore_models: [
      "ActiveStorage::Attachment",
      "ActiveStorage::Blob",
      "ActiveStorage::VariantRecord",
    ]
end
