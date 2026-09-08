import subprocess,time,json
from pathlib import Path
root=Path("/home/maxzhang/factorization-and-loops")
scratch=Path("/tmp/feynfacet-stage1-20260906")
tests=['Tests/EpsilonForm/t_epsilon_form_diagnostic_scope.wls', 'Tests/EpsilonForm/t_off_diagonal_block_epsilon_form_obstructions.wls', 'Tests/Multiquadratic/t_multiquadratic_ansatz_inconsistency_driver.wls', 'Tests/Multiquadratic/t_multiquadratic_off_diagonal_basis_transformation_screen.wls', 'Tests/Multiquadratic/t_multiquadratic_transport_frame.wls', 'Tests/Infrastructure/t_check_levels.wls', 'Tests/Transport/t_finite_field_basis_transformation_reexpression.wls', 'Tests/Core/t_package_generality.wls', 'Tests/Core/t_usage_messages.wls']
results=[]
for test in tests:
    start=time.monotonic()
    output=scratch/(Path(test).stem+".log")
    with output.open("w") as log:
        result=subprocess.run(["taskset","-c","0,1,6,7,8,9,18,19","/usr/local/bin/wolframscript","-file",test],cwd=root,stdout=log,stderr=subprocess.STDOUT)
    record={"Test":test,"ExitCode":result.returncode,"Seconds":time.monotonic()-start,"Log":str(output)}
    results.append(record)
    print(json.dumps(record),flush=True)
    (scratch/"focused-tests.json").write_text(json.dumps(results,indent=2))
