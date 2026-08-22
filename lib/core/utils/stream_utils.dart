/// 极简 combineLatest：任一上游发新数据就用最新值合成一次。
/// 避免仅为一个组合流引入 rxdart。
library;

import 'dart:async';

Stream<R> combineLatest2<A, B, R>(
  Stream<A> streamA,
  Stream<B> streamB,
  R Function(A, B) combine,
) {
  late StreamController<R> controller;
  A? latestA;
  B? latestB;
  var hasA = false, hasB = false, doneA = false, doneB = false;
  late StreamSubscription<A> subA;
  late StreamSubscription<B> subB;

  void emit() {
    if (hasA && hasB) controller.add(combine(latestA as A, latestB as B));
  }

  void checkDone() {
    if (doneA && doneB && !controller.isClosed) controller.close();
  }

  controller = StreamController<R>(
    onListen: () {
      subA = streamA.listen(
        (a) {
          latestA = a;
          hasA = true;
          emit();
        },
        onError: controller.addError,
        onDone: () {
          doneA = true;
          checkDone();
        },
      );
      subB = streamB.listen(
        (b) {
          latestB = b;
          hasB = true;
          emit();
        },
        onError: controller.addError,
        onDone: () {
          doneB = true;
          checkDone();
        },
      );
    },
    onPause: () {
      subA.pause();
      subB.pause();
    },
    onResume: () {
      subA.resume();
      subB.resume();
    },
    onCancel: () async {
      await subA.cancel();
      await subB.cancel();
    },
  );
  return controller.stream;
}
