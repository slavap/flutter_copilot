import 'dart:math' as math;
import 'dart:ui';

import 'scene_graph.dart';
import 'scene_node.dart';

/// Reduces a captured scene to model-friendly nodes.
///
/// Filters out hidden, non-interactive, and off-screen nodes, caps the
/// total count at [maxNodes], and limits similar list items to
/// [maxSimilarVisibleItems] per bucket. The result is sorted
/// top-to-bottom, left-to-right for consistent ordering.
class SceneCompressor {
  /// Creates a scene compressor.
  ///
  /// [maxNodes] caps the total nodes in the output. [maxSimilarVisibleItems]
  /// limits nodes that share the same depth, dimensions, and action
  /// signature (e.g. repeated list items). [viewport] optionally clips
  /// to the visible area.
  const SceneCompressor({
    this.maxNodes = 80,
    this.maxSimilarVisibleItems = 8,
    this.viewport,
  });

  /// Maximum nodes to keep.
  ///
  /// Once this limit is reached, remaining nodes are dropped. Defaults
  /// to 80.
  final int maxNodes;

  /// Maximum similar list items to keep.
  ///
  /// Nodes are bucketed by depth, normalized dimensions, and action
  /// signature. At most this many nodes per bucket are retained.
  /// Defaults to 8.
  final int maxSimilarVisibleItems;

  /// Optional viewport filter.
  ///
  /// When set, only nodes whose bounding rect overlaps this [Rect] are
  /// kept. Useful for limiting context to the visible portion of a
  /// scrollable screen.
  final Rect? viewport;

  /// Compresses [graph] into a smaller scene.
  ///
  /// Applies visibility, viewport, and similarity filters, then sorts
  /// the kept nodes top-to-bottom, left-to-right.
  SceneGraph compress(SceneGraph graph) {
    final kept = <SceneNode>[];
    final seenListBuckets = <String, int>{};

    for (final node in graph.nodes) {
      if (!_shouldKeep(node)) {
        continue;
      }

      final bucket = _listBucket(node);
      if (bucket != null) {
        final count = seenListBuckets.update(bucket, (value) => value + 1,
            ifAbsent: () => 1);
        if (count > maxSimilarVisibleItems) {
          continue;
        }
      }

      kept.add(node);
      if (kept.length >= maxNodes) {
        break;
      }
    }

    final compressed = _sortVisual(kept);
    return SceneGraph(
      nodes: compressed,
      idToSemanticsId: <String, int>{
        for (final node in compressed) node.id: node.semanticsId,
      },
      capturedAt: graph.capturedAt,
    );
  }

  bool _shouldKeep(SceneNode node) {
    if (!node.isVisible) {
      return false;
    }
    if (viewport != null && !node.rect.overlaps(viewport!)) {
      return false;
    }
    if (node.isInteractive) {
      return true;
    }
    return node.hasMeaning && _textScore(node) > 0;
  }

  int _textScore(SceneNode node) {
    return node.label.trim().length +
        node.value.trim().length +
        node.hint.trim().length;
  }

  String? _listBucket(SceneNode node) {
    if (node.rect.height <= 0) return null;
    final normalizedHeight = math.max(1, (node.rect.height / 8).round());
    final normalizedWidth = math.max(1, (node.rect.width / 16).round());
    final actionHash = node.actions.fold(0, (h, a) => h ^ a.index);
    return '$node.depth:$normalizedWidth:$normalizedHeight:$actionHash';
  }

  List<SceneNode> _sortVisual(List<SceneNode> nodes) {
    final sorted = [...nodes];
    sorted.sort((a, b) {
      final top = a.rect.top.compareTo(b.rect.top);
      if (top != 0) {
        return top;
      }
      return a.rect.left.compareTo(b.rect.left);
    });
    return sorted;
  }
}
