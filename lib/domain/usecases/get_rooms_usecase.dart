import '../../data/models/room_model.dart';
import '../../data/repositories/room_repository.dart';

class GetRoomsUseCase {
  final RoomRepository repository;
  GetRoomsUseCase(this.repository);
  Future<List<RoomModel>> call() => repository.getRooms();
}
