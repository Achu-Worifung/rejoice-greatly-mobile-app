import 'package:church_app/services/comments_api.dart';
import 'package:church_app/widgets/comments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _c(String id, String body, {String name = 'Ada L.', bool mine = false, bool team = false}) => {
      'id': id,
      'body': body,
      'authorName': name,
      'mine': mine,
      'fromTeam': team,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toUtc().toIso8601String(),
    };

CommentThread _t(List<Map<String, dynamic>> comments,
        {int? count, int likes = 0, bool liked = false, bool likable = true, String? cantComment}) =>
    CommentThread.fromJson({
      'likable': likable,
      'likes': likes,
      'liked': liked,
      'count': count ?? comments.length,
      'cantComment': cantComment,
      'comments': comments,
    });

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'BASE_URL=https://api.example.org'));

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))));
    await tester.pumpAndSettle();
  }

  test('a like changes the count once, either way', () {
    final t = _t(const [], likes: 4);
    expect(t.withLike(true).likes, 5);
    expect(t.withLike(true).withLike(false).likes, 4);
    expect(t.withLike(false).likes, 4);
  });

  testWidgets('the verse shows its likes and comments, and a like lands straight away', (tester) async {
    final likes = <bool>[];
    await pump(
      tester,
      VerseReactions(
        verseId: 'v1',
        reference: 'Psalm 23:1–3',
        backend: CommentsBackend(
          thread: (_, _) async => _t([_c('1', 'Amen')], likes: 3),
          like: (_, liked) async {
            likes.add(liked);
            return _t([_c('1', 'Amen')], likes: 4, liked: true);
          },
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1 comment'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    await tester.pumpAndSettle();
    expect(likes, [true]);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('posting a comment adds it, and team comments are labelled', (tester) async {
    String? posted;
    var thread = _t([_c('1', 'See you Sunday!', name: 'Pastor M.', team: true)]);
    await tester.pumpWidget(MaterialApp(
      home: CommentsPage(
        subject: CommentSubject.sermon,
        id: '12',
        title: 'Walking by faith',
        backend: CommentsBackend(
          thread: (_, _) async => thread,
          add: (_, _, body) async {
            posted = body;
            thread = _t([...thread.comments.map((c) => _c(c.id, c.body, name: c.authorName, team: c.fromTeam)),
              _c('2', body, name: 'Ben O.', mine: true)]);
            return thread;
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Church team'.toUpperCase()), findsOneWidget);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send_rounded)).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  This one stayed with me.  ');
    await tester.pump();
    await tester.tap(find.byTooltip('Post comment'));
    await tester.pumpAndSettle();
    expect(posted, 'This one stayed with me.');
    expect(find.text('You'), findsOneWidget);
    expect(find.text('This one stayed with me.'), findsOneWidget);
  });

  testWidgets('says why when a member can\'t comment', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CommentsPage(
        subject: CommentSubject.verse,
        id: 'v1',
        title: 'Psalm 23',
        backend: CommentsBackend(
          thread: (_, _) async => _t(const [], cantComment: 'Comments are for members 18 and over.'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Comments are for members 18 and over.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('No comments yet'), findsOneWidget);
  });

  testWidgets('a sermon shows its latest two comments and the way to the rest', (tester) async {
    await pump(
      tester,
      SermonComments(
        sermonId: '12',
        title: 'Walking by faith',
        backend: CommentsBackend(
          thread: (_, _) async => _t([_c('1', 'First'), _c('2', 'Second'), _c('3', 'Third')], count: 5, likable: false),
        ),
      ),
    );
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Third'), findsOneWidget);
    expect(find.text('Read all 5 comments'), findsOneWidget);
  });
}
