/*
	Simple C example.

	- Gathers device information.
	- Moves all axes to there midrange.
	- Tests the waveform functionality.

	Refer to the Madlib_x_x.doc file for function documentation.
*/

#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

#include "Madlib.h"

// Moves an axis over its range of motion in 50 steps occuring at 2 millisecond intervals.
void SynchronousWaveformAquisition(unsigned int axis, double Cal, int handle, short is20bit);

int main ()
{
	char dummy;
	int j, handle;
	struct ProductInformation pi;

	// A handle identifies which device to communicate with.  This example 
	// assumes that only one device is connected.  MCL_InitHandle will return
	// a handle to the first device it finds.
	handle = MCL_InitHandle();
	if(handle == 0) {
		printf("Cannot get a handle to the device\n");
		printf("Enter any key to continue\n");
		scanf_s("%c", &dummy, 1);
		return 1;
	}

	// Prints some information about the device to a console.
	MCL_PrintDeviceInfo(handle);

	// Fills a structure with information about the Nano-Drive.
	MCL_GetProductInfo(&pi, handle);

	// For each valid axis perform a few simple operations.
	for(j = 0; j < 3; j++)
	{
		unsigned int axis;
		char axis_letter;
		double current_position;
		double calibration;

		// Checks if an axis is valid.
		//		axis_bitmap = 0x---E AZYX
		//	    E = Encoder
		//		A = Auxillary Axis
		//		Z = Z Axis
		//		Y = Y Axis
		//		X = X Axis
		if((pi.axis_bitmap & (0x01 << j)) == 0)		
			continue;

		// Move the axis to 50% of its range of motion.
		axis = j+1;
		switch(axis) {
			case 1:
				axis_letter = 'X'; break;
			case 2:
				axis_letter = 'Y'; break;
			case 3:
				axis_letter = 'Z'; break;
		}

		// Read the position of the axis.
		current_position = MCL_SingleReadN(axis, handle);
		printf("\n%c Axis position in microns %f\n", axis_letter, current_position);

		// Determine how far the axis can move.
		calibration = MCL_GetCalibration(axis, handle);

		// Move the axis to its midrange.
		printf("Move %c Axis to 50 percent of its range of motion\n", axis_letter);
		MCL_SingleWriteN(calibration * .50, axis, handle);
		
		// After moving the stage some time is required for it to complete its move.
		Sleep(100);
		
		// Read the settled position.
		current_position = MCL_SingleReadN(axis, handle);
		printf("%c Axis position in microns %f\n", axis_letter, current_position);

		// Test the waveform functionality if it is supported. Waveforms are 
		// supported if bit 4 is set in the firmware profile.
		if( (pi.FirmwareProfile & 0x0010) == 0x0010 )
		{
			short is20bit = 0;
			if(pi.Product_id == 0x2201 ||
			   pi.Product_id == 0x2203 ||
			   pi.Product_id == 0x2253 
			   )
			{
				is20bit = 1;
			}

			SynchronousWaveformAquisition(axis, calibration, handle, is20bit);
		}
	}

	// MCL_ReleaseHandle should be called to properly release DLL resources.
	MCL_ReleaseHandle(handle);

	printf("\nEnter any key to continue\n");
	scanf_s("%c", &dummy, 1);

	return 0;
}


void SynchronousWaveformAquisition(unsigned int axis, double Cal, int handle, short is20bit)
{
	int error;
	unsigned int datapoints, i;
	double milliseconds;
	double *waveform = NULL;

	error = MCL_SUCCESS;
	datapoints = 50;
	milliseconds = 2;
	
	// In 20 bit systems milliseconds is an index to a table containing valid ADC rates.
	// See Madlib.doc for more information.
	if(is20bit == 1)
		milliseconds = 6;

	waveform = (double *) malloc ( sizeof(double) * datapoints );
	for(i = 0; i < datapoints; i++)
		waveform[i] = Cal/datapoints*i;

	/*
		Example of synchronous waveform acquisition.
		
		-MCL_Setup_LoadWaveFormN loads the position control waveform to the axis.
		-MCL_Setup_ReadWaveFormN sets some internal values in the NanoDrive.
		-MCL_TriggerWaveformAcquisition triggers both waveforms simultaneously.
	*/
	error = MCL_Setup_LoadWaveFormN(axis, datapoints, milliseconds, waveform, handle);
	if(error != MCL_SUCCESS)
		goto FAIL;

	error = MCL_Setup_ReadWaveFormN(axis, datapoints, milliseconds, handle);
	if(error != MCL_SUCCESS)
		goto FAIL;

	error = MCL_TriggerWaveformAcquisition(axis, datapoints, waveform, handle);
	if(error != MCL_SUCCESS)
		goto FAIL;

	printf("Waveform Functionality Tested Successfully\n");

	/*Print the waveform data points.*/
	//for(i = 0; i < datapoints; i++)
	//	printf("%d: %f\n", i, waveform[i]);

FAIL:
	free(waveform);
	if(error != MCL_SUCCESS)
		printf("Failed Waveform Functionality Test\n");
}