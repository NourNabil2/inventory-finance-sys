import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:bungee_manage_sys/core/errors/failures.dart';

/// ============================================================================
/// BASE USE CASE INTERFACE
/// ============================================================================
///
/// العقد الأساسي اللي بتمشي عليه كل الـ UseCases في التطبيق.
/// بيجبرك إنك ترجع [Either] عشان تتعامل مع الـ Errors (Failure)
/// والـ Success (Type) بشكل نظيف وآمن.
///
/// [Type]: نوع الداتا اللي هترجع في حالة النجاح (زي String, Entity, أو void)
/// [Params]: المعاملات (Parameters) اللي محتاجها الـ UseCase عشان يشتغل
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// ============================================================================
/// NO PARAMS CLASS
/// ============================================================================
///
/// بنستخدم الكلاس ده لما يكون الـ UseCase مش محتاج أي Parameters عشان يشتغل.
/// مثال: جلب كل العملاء
/// class GetCustomersUseCase implements UseCase<List<CustomerEntity>, NoParams>
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}