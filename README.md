# Compositional_Grid_Code
Data and code of the article "Compositional Grid Codes with Guarantee on Both Stability and Dynamic Performance"

This source code repository accompanies the following paper (open-sourced upon acceptance):

> X. Peng, C. Fu, Z. Li, X. Ru, Z. Wang and F. Liu, "Compositional Grid Codes with Guarantee on Both Stability and Dynamic Performance," IEEE Transactions on Power Systems, 2026.

The full paper and the source code can be found at: https://github.com/lingo01/Compositional_Grid_Code.

For any questions or uses of the source codes, please feel free to contact the first author, Xiaoyu Peng (pengxy19@tsinghua.org.cn), and the corresponding author, Feng Liu (lfeng@mail.tsinghua.edu.cn).

**CITATION**: If you use this code in your work, whether directly or indirectly, please cite the above paper.

**LICENSE**: This work is licensed under the MIT License. See the [LICENSE](LICENSE) file in the repository for details.



# Introduction to the source code

All code is written in `MATLAB` and can be run directly in `MATLAB 2018a` or later versions.

The simulations are conducted on a modified IEEE 118-bus system with inverter-interface devices. The codes can also be employed to verify the results on other benchmark systems, as introduced later. For clarity, this letter adopts a linearized dynamic model to verify the theoretical results.

The simulations are shown in Fig.3 in the paper. Next, we explain how to generate all the data and figures of this paper in detail.



## How to Generate Figure 3

To reproduce Figure 3 from the paper, simply run the `main.m` script in MATLAB. This script performs simulations on the IEEE 118-bus system.

### Configuration

You can customize the simulation by modifying the following parameters in the `main.m` script:

*   **System Case**:
    *   `casename` (Line 14): Change the system benchmark, e.g., `'case118'`, `'case39'`, `'case9'`.
*   **Operating Conditions**:
    *   `loadscaling` (Line 15): Adjust the load scaling factor (`rho_load` in the paper) to simulate different operating scenarios (e.g., `1.0`, `1.2`).
*   **Grid Code**:
    *   `stability_code_flag` (Line 24): Set to `1` to enable the stability grid code or `0` to disable it. This allows you to compare system dynamics with and without the proposed compositional grid code.

### Simulation Output

The script will generate and save the frequency response plot as an `.emf` vector graphics file in the project's root directory. The filename will indicate the configuration used, for example: `simulation_case118_withCode_loadscaling1.2.emf`.

### Reproduction of Article

To reproduce Fig.3 of this paper, setting `loadscling, stability_code_flag = (1.0, 0), (1.2, 0), (1.0, 1), (1.2, 1)` respectively to generate Fig.3(a), (b), (c) and (d) in order.



## Verification on Other Benchmark Systems

The code is structured to allow for verification on other standard benchmark systems. To do this:

1. **Change `casename`**: Modify the `casename` variable in `main.m` (Line 14) to your desired system (e.g., `'case9'`).

2.  **Generate H-Net Data**: Uncomment and run the `func_Hnet_generator` function in `main.m` (Line 29). This will compute and save the necessary `Hnet_info.mat` file for the new system configuration into the `data&figure/` directory.
    ```matlab
    % func_Hnet_generator(casename, 1, loadscaling);
    ```
    
    **To use this function, make sure you have installed MATPOWER**: See https://matpower.org for install instruction.
    
3.  **Run Simulation**: Execute the `main.m` script. The results for the new system will be saved automatically. 
