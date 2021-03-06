import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:schulcloud/app/app.dart';

import '../data.dart';
import 'article_image.dart';
import 'section.dart';
import 'theme.dart';

class ArticlePreview extends StatelessWidget {
  const ArticlePreview({
    @required this.article,
    this.showPicture = true,
    this.showDetailedDate = false,
  })  : assert(article != null),
        assert(showPicture != null),
        assert(showDetailedDate != null);

  factory ArticlePreview.placeholder() {
    return ArticlePreview(article: null, showPicture: false);
  }

  final Article article;
  final bool showPicture;
  final bool showDetailedDate;

  bool get _isPlaceholder => article == null;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final s = context.s;

    return FancyCard(
      onTap: _isPlaceholder
          ? null
          : () => context.navigator.pushNamed('/news/${article.id}'),
      child: Provider<ArticleTheme>(
        create: (_) => ArticleTheme(darkColor: Colors.purple, padding: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Section(
              child: Text(
                'Section',
                style: TextStyle(color: Colors.white),
              ),
            ),
            _buildImage(),
            FancyText(
              article?.title,
              style: theme.textTheme.display2,
            ),
            EntityBuilder<User>(
              id: article.authorId,
              builder: (context, snapshot, fetch) {
                var authorName = snapshot.data?.displayName;
                if (snapshot.hasError &&
                    snapshot.error is ErrorAndStacktrace &&
                    (snapshot.error as ErrorAndStacktrace).error
                        is ForbiddenError) {
                  authorName = s.general_user_unknown;
                }

                if (authorName != null || !snapshot.hasError) {
                  return FancyText(
                    authorName == null
                        ? null
                        : s.news_articlePreview_subtitle(
                            article.publishedAt.shortDateString, authorName),
                    emphasis: TextEmphasis.medium,
                    style: theme.textTheme.subtitle,
                    estimatedWidth: 192,
                  );
                }

                return handleError((_, __, ___) {
                  assert(
                    false,
                    "This shouldn't be called as the handler is only called with an error.",
                  );
                  return null;
                })(context, snapshot, fetch);
              },
            ),
            SizedBox(height: 4),
            FancyText.preview(
              article?.content,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_isPlaceholder) {
      return GradientArticleImageView(imageUrl: null);
    } else if (article.imageUrl == null) {
      return Container();
    } else {
      return Hero(
        tag: article,
        child: GradientArticleImageView(imageUrl: article?.imageUrl),
      );
    }
  }
}
