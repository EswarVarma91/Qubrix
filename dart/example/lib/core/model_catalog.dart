/// Model catalog for HuggingFace models
/// Developers can add their own HuggingFace repo URLs here
/// For SDK consumers: just pass the HuggingFace repo ID to downloadModel()

class ModelCatalogEntry {
  final String repoId; // HuggingFace repo ID (e.g., "facebook/opt-1.3b")
  final String displayName;
  final String description;
  final String? license;
  final String? hfUrl; // Full HuggingFace URL if different from repoId
  final List<HfModelVariant> variants;
  final String? taskType;
  final double? minQuality;
  final bool isOfficial;

  const ModelCatalogEntry({
    required this.repoId,
    required this.displayName,
    required this.description,
    this.license,
    this.hfUrl,
    required this.variants,
    this.taskType,
    this.minQuality,
    this.isOfficial = false,
  });

  String get downloadUrl => hfUrl ?? 'https://huggingface.co/$repoId';
}

class HfModelVariant {
  final String quantization; // e.g., "float32", "float16", "int8", "int4"
  final int downloadSizeMb;
  final int memoryRequirementMb;
  final double estimatedLatencyMs;
  final String? customFilePattern; // Custom file pattern for this variant

  const HfModelVariant({
    required this.quantization,
    required this.downloadSizeMb,
    required this.memoryRequirementMb,
    required this.estimatedLatencyMs,
    this.customFilePattern,
  });
}

/// Pre-configured HuggingFace models for common use cases
/// Developers can use these or add their own
class HuggingFaceModels {
  HuggingFaceModels._();

  // Text classification models
  static const sentimentAnalysis = ModelCatalogEntry(
    repoId: 'distilbert-base-uncased-finetuned-sst-2-english',
    displayName: 'Sentiment Analysis',
    description: 'DistilBERT fine-tuned for sentiment analysis',
    license: 'Apache 2.0',
    variants: [
      HfModelVariant(
        quantization: 'float32',
        downloadSizeMb: 250,
        memoryRequirementMb: 500,
        estimatedLatencyMs: 50,
      ),
      HfModelVariant(
        quantization: 'int8',
        downloadSizeMb: 68,
        memoryRequirementMb: 200,
        estimatedLatencyMs: 30,
      ),
      HfModelVariant(
        quantization: 'int4',
        downloadSizeMb: 36,
        memoryRequirementMb: 120,
        estimatedLatencyMs: 25,
      ),
    ],
    taskType: 'text_classification',
    minQuality: 0.85,
    isOfficial: true,
  );

  static const toxicityDetection = ModelCatalogEntry(
    repoId: 'martin-ha/toxic-comment-model',
    displayName: 'Toxicity Detection',
    description: 'Detects toxic content in text',
    license: 'MIT',
    variants: [
      HfModelVariant(
        quantization: 'float32',
        downloadSizeMb: 420,
        memoryRequirementMb: 800,
        estimatedLatencyMs: 80,
      ),
      HfModelVariant(
        quantization: 'int8',
        downloadSizeMb: 110,
        memoryRequirementMb: 300,
        estimatedLatencyMs: 50,
      ),
    ],
    taskType: 'text_classification',
    minQuality: 0.9,
    isOfficial: false,
  );

  // Text generation models
  static const gpt2Small = ModelCatalogEntry(
    repoId: 'gpt2',
    displayName: 'GPT-2 Small',
    description: '117M parameter text generation model',
    license: 'MIT',
    variants: [
      HfModelVariant(
        quantization: 'float32',
        downloadSizeMb: 500,
        memoryRequirementMb: 1000,
        estimatedLatencyMs: 100,
      ),
      HfModelVariant(
        quantization: 'float16',
        downloadSizeMb: 250,
        memoryRequirementMb: 600,
        estimatedLatencyMs: 80,
      ),
      HfModelVariant(
        quantization: 'int8',
        downloadSizeMb: 128,
        memoryRequirementMb: 350,
        estimatedLatencyMs: 60,
      ),
      HfModelVariant(
        quantization: 'int4',
        downloadSizeMb: 65,
        memoryRequirementMb: 200,
        estimatedLatencyMs: 45,
      ),
    ],
    taskType: 'text_generation',
    minQuality: 0.7,
    isOfficial: true,
  );

  static const optSmall = ModelCatalogEntry(
    repoId: 'facebook/opt-1.3b',
    displayName: 'OPT 1.3B',
    description: 'Meta\'s 1.3B parameter open pre-trained transformer',
    license: 'MIT',
    variants: [
      HfModelVariant(
        quantization: 'float16',
        downloadSizeMb: 2600,
        memoryRequirementMb: 5000,
        estimatedLatencyMs: 200,
      ),
      HfModelVariant(
        quantization: 'int8',
        downloadSizeMb: 700,
        memoryRequirementMb: 2000,
        estimatedLatencyMs: 150,
      ),
    ],
    taskType: 'text_generation',
    minQuality: 0.75,
    isOfficial: true,
  );

  // Embedding models
  static const sentenceTransformer = ModelCatalogEntry(
    repoId: 'sentence-transformers/all-MiniLM-L6-v2',
    displayName: 'Sentence Embeddings',
    description: 'Fast sentence embedding model for semantic search',
    license: 'Apache 2.0',
    variants: [
      HfModelVariant(
        quantization: 'float32',
        downloadSizeMb: 92,
        memoryRequirementMb: 200,
        estimatedLatencyMs: 20,
      ),
      HfModelVariant(
        quantization: 'int8',
        downloadSizeMb: 25,
        memoryRequirementMb: 80,
        estimatedLatencyMs: 15,
      ),
    ],
    taskType: 'feature_extraction',
    minQuality: 0.8,
    isOfficial: true,
  );

  // Question answering
  static const qaModel = ModelCatalogEntry(
    repoId: 'distilbert-base-cased-distilled-squad',
    displayName: 'Question Answering',
    description: 'DistilBERT fine-tuned on SQuAD for QA',
    license: 'Apache 2.0',
    variants: [
      HfModelVariant(
        quantization: 'float32',
        downloadSizeMb: 250,
        memoryRequirementMb: 500,
        estimatedLatencyMs: 40,
      ),
      HfModelVariant(
        quantization: 'int8',
        downloadSizeMb: 68,
        memoryRequirementMb: 200,
        estimatedLatencyMs: 28,
      ),
    ],
    taskType: 'question_answering',
    minQuality: 0.85,
    isOfficial: true,
  );

  // Custom model entry for developer-specified HuggingFace repo
  static ModelCatalogEntry custom({
    required String repoId,
    required String displayName,
    String? description,
    String? license,
    List<HfModelVariant>? variants,
    String? taskType,
    double? minQuality,
  }) {
    return ModelCatalogEntry(
      repoId: repoId,
      displayName: displayName,
      description: description ?? 'Custom HuggingFace model',
      license: license,
      variants: variants ??
          [
            HfModelVariant(
              quantization: 'float32',
              downloadSizeMb: 500,
              memoryRequirementMb: 1000,
              estimatedLatencyMs: 100,
            ),
          ],
      taskType: taskType,
      minQuality: minQuality,
      isOfficial: false,
    );
  }

  /// All available models
  static List<ModelCatalogEntry> get all => [
        sentimentAnalysis,
        toxicityDetection,
        gpt2Small,
        optSmall,
        sentenceTransformer,
        qaModel,
      ];

  /// Models by task type
  static List<ModelCatalogEntry> forTask(String? taskType) {
    if (taskType == null || taskType.isEmpty) return all;
    return all.where((m) => m.taskType == taskType).toList();
  }

  /// Find model by repo ID
  static ModelCatalogEntry? findByRepoId(String repoId) {
    return all.where((m) => m.repoId == repoId).firstOrNull;
  }
}
