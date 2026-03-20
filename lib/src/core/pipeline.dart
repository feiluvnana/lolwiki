abstract class Pipeline<T> {
  const Pipeline();

  Future<T?> handle(T data);
}
