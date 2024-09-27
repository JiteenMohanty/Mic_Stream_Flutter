import requests
import numpy as np
import wave
import matplotlib.pyplot as plt

# Define parameters for the WAV file and audio processing
SAMPLE_RATE = 16000  # Sample rate of the audio (16kHz)
NUM_CHANNELS = 1  # Mono audio
SAMPLE_WIDTH = 2  # 16-bit audio (2 bytes per sample)

# Function to process incoming audio
# Function to process incoming audio
def process_audio(response):
    print("Connected to HTTP server")

    # List to store RMS values for loudness graph
    rms_values = []

    # Open WAV file to save incoming audio stream
    wav_file = wave.open("received_audio.wav", "wb")
    wav_file.setnchannels(NUM_CHANNELS)
    wav_file.setsampwidth(SAMPLE_WIDTH)
    wav_file.setframerate(SAMPLE_RATE)

    try:
        # Read the response content in chunks
        for chunk in response.iter_content(chunk_size=1024):
            # Convert received audio bytes to numpy array
            audio_data = np.frombuffer(chunk, dtype=np.int16)

            # Save the audio data to the WAV file
            wav_file.writeframes(chunk)

            # Calculate RMS (Root Mean Square) of the audio data
            rms = np.sqrt(np.mean(np.square(audio_data)))
            rms_values.append(rms)
            print(f"Received audio chunk of size: {len(audio_data)}, RMS: {rms}")

    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        # Close the WAV file
        wav_file.close()
        print("Connection closed, audio file saved.")

        # Plot the loudness (RMS) over time
        plt.plot(rms_values)
        plt.title('Audio Loudness (RMS) Over Time')
        plt.xlabel('Audio Chunks')
        plt.ylabel('RMS')
        plt.grid(True)
        plt.show()

# Main function to connect to HTTP server and start streaming
def main():
    # Get HTTP/HTTPS endpoint from the user
    endpoint = input("Enter the HTTP endpoint (e.g., https://your-endpoint.com): ")

    # Attempt to connect to the HTTP server
    try:
        response = requests.get(endpoint, stream=True)
        process_audio(response)
    except requests.exceptions.RequestException as e:
        print(f"Failed to connect to HTTP endpoint. Check your URL: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()