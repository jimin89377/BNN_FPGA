#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xtime_l.h"  // To measure of processing time
#include <stdlib.h>	  // To generate rand value
#include <assert.h>

#define DATA_GEN 1
#define SW_RUN 2
#define HW_RUN 3
#define CHECK 4

#define IDLE_0 1 << 0
#define RUN_0  1 << 1
#define DONE_0 1 << 2
#define IDLE_1 1 << 3
#define RUN_1  1 << 4
#define DONE_1 1 << 5

#define REG0 0//CTRL_REG
#define REG1 4//STATUS_REG
#define REG2 8//MEM0_ADDR_REG
#define REG3 12//MEM0_DATA_REG
#define REG4 16//MEM1_ADDR_REG
#define REG5 20//MEM1_DATA_REG
#define REG6 24//MEM3_ADDR_REG
#define REG7 28//MEM3_DATA_REG
#define REG8 32//MEM4_ADDR_REG
#define REG9 36//MEM4_DATA_REG


#define IN_DATA_WIDTH 28
#define WEGT_WIDTH 3
#define STRIDE 1
#define IN_CHANNEL 3
#define OUT_CHANNEL_0 3
#define OUT_CHANNEL_1 5

#define WEGT_1CH 9

//--layer 1 parameters-------------------------------------------------------------
#define WEGT_SIZE_0 27
#define IN_DATA_WIDTH_0 28
#define IN_DATA_1CH_0 784
#define IN_DATA_SIZE_0 2352
#define OUT_DATA_WIDTH_0 26
#define OUT_DATA_1CH_0 676


//--layer 2 parameters-------------------------------------------------------------
#define WEGT_SIZE_1 27
#define IN_DATA_WIDTH_1 26
#define IN_DATA_1CH_1 676
#define IN_DATA_SIZE_1 2028
#define OUT_DATA_WIDTH_1 24
#define OUT_DATA_1CH_1 576

#define Write_32(BaseAddress, RegOffset, Data)\
	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))
#define Read_32(BaseAddress, RegOffset)\
	Xil_In32((BaseAddress) + (RegOffset))

#define ADDR 0x40000000 // 기본 주소

void bnn_calculation();

int main() {
	printf("main func access");
    int data;
    int case_num;
    unsigned int read_data;
    XTime tStart, tEnd;
    int i, j, k;

    u32 input_0[IN_CHANNEL][IN_DATA_WIDTH] = {0, };
    u32 wegt_0[OUT_CHANNEL_0] = {0, };
    u32 wegt_1[OUT_CHANNEL_1] = {0, };

    u32 sliced_input_0[OUT_DATA_1CH_0] = {0, };
    u32 sliced_input_1[OUT_DATA_1CH_1] = {0, };

    u32 xnor_result_0[OUT_CHANNEL_0][OUT_DATA_1CH_0] = {0, };
    u32 xnor_result_1[OUT_CHANNEL_1][OUT_DATA_1CH_1] = {0, };

    u32 popcnt_result_0[OUT_CHANNEL_0][OUT_DATA_1CH_0] = {0, };
    u32 popcnt_result_1[OUT_CHANNEL_1][OUT_DATA_1CH_1] = {0, };

    u32 sw_result_0[OUT_CHANNEL_0][OUT_DATA_1CH_0] = {0, };
    u32 sw_result_1[OUT_CHANNEL_1][OUT_DATA_1CH_1] = {0, };

    u32 hw_result_1[OUT_CHANNEL_1][OUT_DATA_1CH_1] = {0, };

    while (1) {
        printf("======= MENU ======\n");
        printf("plz input run mode\n");
        printf("1. RAND_DATA_GEN \n");
        printf("2. SW RUN \n");
        printf("3. HW RUN \n");
        printf("4. CHECK SW vs HW result\n");

        scanf("%d", &case_num);

        if (case_num == DATA_GEN) {
            printf("\nInput srand value.\n");
            scanf("%d", &data);
            srand(data);

            for(i = 0; i < IN_CHANNEL; i++)
            {
            	for(j = 0; j < IN_DATA_WIDTH_0; j++)
            	{
            		for(k = 0; k < IN_DATA_WIDTH_0; k++)
            		{
            			input_0[i][j] = (input_0[i][j] << 1) | (rand() % 2);
            		}
            	}
            }

            for(i = 0; i < OUT_CHANNEL_0; i++)
            {
            	for(j = 0; j < WEGT_SIZE_0; j++)
            	{
            		wegt_0[i] = (wegt_0[i] << 1) | (rand() % 2);
            	}
            }

            for(i = 0; i < OUT_CHANNEL_1; i++)
            {
            	for(j = 0; j < WEGT_SIZE_1; j++)
            	{
            		wegt_1[i] = (wegt_0[i] << 1) | (rand() % 2);
            	}
            }

            printf("Input gen \n\n");
        }

         else if(case_num == SW_RUN)
        {
        	double sw_calc_time = 0.0;

        	printf("\nSW CALC START!\n");

        	XTime_GetTime(&tStart);

        	bnn_calculation(IN_CHANNEL, WEGT_SIZE_0, IN_DATA_WIDTH_0, IN_DATA_1CH_0, OUT_DATA_WIDTH_0, OUT_DATA_1CH_0, OUT_CHANNEL_0,
                    			input_0, wegt_0, sliced_input_0, xnor_result_0, popcnt_result_0, sw_result_0);

        	bnn_calculation(OUT_CHANNEL_0, WEGT_SIZE_1, IN_DATA_WIDTH_1, IN_DATA_1CH_1, OUT_DATA_WIDTH_1, OUT_DATA_1CH_1, OUT_CHANNEL_1,
        	                    sw_result_0, wegt_1, sliced_input_1, xnor_result_1, popcnt_result_1, sw_result_1);

			XTime_GetTime(&tEnd);
			sw_calc_time += 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000);

            printf("\nSW Calculation Done \n");
            printf("\nSW Calculation time %.2f us.\n\n",sw_calc_time);
        }

        else if (case_num == HW_RUN) {
            double hw_processing_time = 0.0;
            Write_32(ADDR, REG0, 0); // init core ctrl reg
            Write_32(ADDR, REG2, 0);
            Write_32(ADDR, REG4, 0);
            Write_32(ADDR, REG6, 0);
            Write_32(ADDR, REG8, 0);

            printf("\nWeight write Start\n");

            XTime_GetTime(&tStart);
            // weight_0 Loading to BRAM 1 (784 * 32)
            for (i = 0; i < WEGT_WIDTH; i++) // 25088
            {
                Write_32(ADDR, REG5, wegt_0[i]);
            }
            // weight_1 Loading to BRAM 3 (128 * 8)
            for (j = 0; j < WEGT_WIDTH; j++) // 1024
            {
                Write_32(ADDR, REG7, wegt_1[j]);
            }
            XTime_GetTime(&tEnd);

            printf("Weight write Done\n");

            printf("\nWeight write to BRAM 1,3,5 time : %.2f us.\n\n",
                1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND / 1000000));

            hw_processing_time += 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND / 1000000);

            printf("input write Start\n");
            // input Loading to BRAM 0 (784)

            XTime_GetTime(&tStart);
            for(i = 0; i < IN_CHANNEL; i++)
            {
            	for(j = 0; j < IN_DATA_1CH_0; j++)
            	{
            		Write_32(ADDR, REG3, input_0[i][j]);
            	}
            }
            XTime_GetTime(&tEnd);

            printf("input write Done\n");

            printf("\nInput write to BRAM 0 time : %.2f us.\n\n",
                1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND / 1000000));

            hw_processing_time += 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND / 1000000);

            // check FC_Layer_0 IDLE
            do{
                read_data = Read_32(ADDR, REG1);
            } while ((read_data & IDLE_0) != IDLE_0);

            printf("BNN Layer calc start\n");
            // run
            Write_32(ADDR, REG0, (u32)(0x80000000)); // MSB run

            // wait done_1
            XTime_GetTime(&tStart);
            do{
                read_data = Read_32(ADDR, REG1);
            } while ((read_data & DONE_1) != DONE_1);
            XTime_GetTime(&tEnd);

            printf("BNN Layer calc done\n\n");
            printf("BNN layer calc time : %.2f us. \n\n",
                1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND / 1000000));
            hw_processing_time += 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND / 1000000);

            printf("Read Result start\n");
            // Read Result to hw_result
            XTime_GetTime(&tStart);
            for(i = 0; i < OUT_CHANNEL_1; i++)
            {
            	for(j = 0; j < OUT_DATA_1CH_1; j++)
            	{
            		hw_result_1[i][j] = Read_32(ADDR, REG9);
            	}
            }
            XTime_GetTime(&tEnd);

            printf("Read Result Done\n");
            printf("\nRead time %.2f us.\n",
                1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND / 1000000));
            hw_processing_time += 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND / 1000000);

            printf("\nTotal HW Run time %.2f us.\n\n", hw_processing_time);
        }
        // Check Result
        else if (case_num == CHECK) {

            for(i = 0; i < OUT_CHANNEL_1; i++)
            {
            	for(j = 0; j < OUT_DATA_1CH_1; j++)
            	{
            		if(sw_result_1[i][j] != hw_result_1[i][j])
            		{
            			printf("Mismatch!! sw_result_1 = %lu, hw_result_1 = %lu [%d][%d]", sw_result_1[i][j], hw_result_1[i][j], i, j);
            		}
            	}
            }
            printf("\n");
        }
        else {
            break;
        }
    }
    printf("system shut down\n");
    return 0;
}

void bnn_calculation(int in_channel, int wegt_size, int in_data_width, int in_data_1ch, int out_data_width, int out_data_1ch, int out_channel,
		u32 input[][in_data_1ch], u32 wegt[wegt_size], u32 sliced_input[out_data_1ch], u32 xnor_result[][out_data_1ch],
	u32 popcnt_result[][out_data_1ch], u32 result[][out_data_1ch])
{
    int i, j, k, l;
    //--step 1 ) Window Extraction--------------------

    for(i = 0; i < out_data_width; i++)
    {
    	for(j = 0; j < out_data_width; j++)
    	{
    		for(k = 0; k < in_channel; k++)
    		{
    			for(l = 0; l < WEGT_WIDTH; l++)
    			{
    				sliced_input[i * out_data_width + j] = (sliced_input[i * out_data_width + j] << WEGT_WIDTH);
    				sliced_input[i * out_data_width + j]
    					|= (input[k][i + l] >> (in_data_width - WEGT_WIDTH - j)) & 0x00000007;
    			}
    		}
    	}
    }
    //--step 2 ) Xnor calculation--------------------

    for(i = 0; i < out_channel; i++)
    {
    	for(j = 0; j < out_data_1ch; j++)
    	{
    		xnor_result[i][j] = ~(sliced_input[j] ^ wegt[i]);
    	}
    }

    //--step 3 ) Popcount calculation----------------
    u32 count;
    for(i = 0; i < out_channel; i++)
    {
    	for(j = 0; j < out_data_1ch; j++)
    	{
    		count = 0;
    		for(k = 0; k < wegt_size; k++)
    		{
    			count += ((xnor_result[i][j] >> k) & 0x00000001);
    		}
    		popcnt_result[i][j] = count;
    	}
    }
    //--step 4 ) Sign Activation--------------------

    for(i = 0; i < out_channel; i++)
    {
    	for(j = 0; j < out_data_1ch; j++)
    	{
    		result[i][j] = ((popcnt_result[i][j] << 1) > wegt_size) ? 1 : 0;
    	}
    }
}
