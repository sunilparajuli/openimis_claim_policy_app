import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/feature/shared/models/csu_input_limits.dart';
import 'package:openimis_claim_policy_app/feature/shared/models/csu_master_data.dart';

void main() {
  Map<String, dynamic> masterData(List<Map<String, dynamic>> configuration) => {
    for (final key in CsuMasterData.requiredSections) key: <Object>[],
    'ModuleConfiguration': configuration,
  };

  test('uses the documented defaults without server overrides', () {
    final limits = CsuInputLimits.fromMasterData(
      CsuMasterData.fromJson(masterData([])),
    );
    expect(limits.mpiMinLength, 12);
    expect(limits.mpiMaxLength, 20);
    expect(limits.chequeMinLength, 6);
  });

  test('uses exposed frontend server values', () {
    final data = CsuMasterData.fromJson(
      masterData([
        {'key': 'mpiMinLength', 'value': 13, 'layer': 'fe', 'is_exposed': true},
        {
          'key': 'mpiMaxLength',
          'value': '22',
          'layer': 'fe',
          'is_exposed': true,
        },
        {
          'key': 'chequeMinLength',
          'value': 8,
          'layer': 'fe',
          'is_exposed': true,
        },
        {'key': 'mpiMinLength', 'value': 2, 'layer': 'be', 'is_exposed': true},
      ]),
    );
    final limits = CsuInputLimits.fromMasterData(data);
    expect(limits.mpiMinLength, 13);
    expect(limits.mpiMaxLength, 22);
    expect(limits.chequeMinLength, 8);
  });

  test('validates MPI and cheque lengths', () {
    const limits = CsuInputLimits(
      mpiMinLength: 3,
      mpiMaxLength: 5,
      chequeMinLength: 4,
    );
    expect(limits.validateMpi('12'), contains('at least 3'));
    expect(limits.validateMpi('123456'), contains('at most 5'));
    expect(limits.validateMpi('1234'), isNull);
    expect(limits.validateCheque('123'), contains('at least 4'));
    expect(limits.validateCheque('1234'), isNull);
  });

  test('reads real module configuration JSON exported by CSU tools', () {
    final data = CsuMasterData.fromJson({
      for (final key in CsuMasterData.requiredSections) key: <Object>[],
      'ModuleConfiguration': [
        {
          'module': 'fe-insuree',
          'config':
              '{"insureeForm.chfIdMinLength":14,"insureeForm.chfIdMaxLength":18}',
          'layer': 'fe',
          'is_exposed': true,
        },
        {
          'module': 'fe-policy',
          'config': '{"minChequeNumberRequired":9}',
          'layer': 'fe',
          'is_exposed': true,
        },
      ],
    });

    final limits = CsuInputLimits.fromMasterData(data);
    expect(limits.mpiMinLength, 14);
    expect(limits.mpiMaxLength, 18);
    expect(limits.chequeMinLength, 9);
  });
}
