import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as htmlparser;

const Color _teal = Color(0xFF0B5952);

/// عارض HTML بسيط يدعم: h3 h4 p ul ol li b/strong br div.callout
class HtmlView extends StatelessWidget {
  final String data;
  const HtmlView(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final body = htmlparser.parse(data).body;
    final children = <Widget>[];
    if (body != null) {
      for (final node in body.nodes) {
        final w = _block(node);
        if (w != null) children.add(w);
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget? _block(dom.Node node) {
    if (node is dom.Text) {
      final t = node.text.trim();
      if (t.isEmpty) return null;
      return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(t));
    }
    if (node is! dom.Element) return null;
    final tag = node.localName;
    switch (tag) {
      case 'h3':
        return Padding(padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(node.text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)));
      case 'h4':
        return Padding(padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Text(node.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _teal)));
      case 'ul':
      case 'ol':
        final items = node.children.where((e) => e.localName == 'li').toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tag == 'ol' ? '${i + 1}. ' : '•  ', style: const TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text.rich(_inline(items[i]))),
              ]),
            ),
        ]);
      case 'div':
        final isCallout = (node.attributes['class'] ?? '').contains('callout');
        if (isCallout) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                border: Border(left: BorderSide(color: const Color(0xFF059669), width: 4)),
                borderRadius: BorderRadius.circular(10)),
            child: Text.rich(_inline(node), style: const TextStyle(color: Color(0xFF0F5132))),
          );
        }
        return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text.rich(_inline(node)));
      case 'p':
      default:
        return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text.rich(_inline(node)));
    }
  }

  TextSpan _inline(dom.Node node) {
    final spans = <InlineSpan>[];
    for (final c in node.nodes) {
      if (c is dom.Text) {
        spans.add(TextSpan(text: c.text));
      } else if (c is dom.Element) {
        if (c.localName == 'br') {
          spans.add(const TextSpan(text: '\n'));
        } else if (c.localName == 'b' || c.localName == 'strong') {
          spans.add(TextSpan(text: c.text, style: const TextStyle(fontWeight: FontWeight.bold)));
        } else {
          spans.add(_inline(c));
        }
      }
    }
    return TextSpan(children: spans, style: const TextStyle(fontSize: 14.5, height: 1.6));
  }
}
