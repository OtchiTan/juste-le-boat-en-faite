using Godot;
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using System.Collections.Generic;
using System.Linq;

namespace GodotONNX
{
	/// <include file='docs/ONNXInference.xml' path='docs/members[@name="ONNXInference"]/ONNXInference/*'/>
	public partial class ONNXInference : GodotObject
	{

		private InferenceSession session;
		/// <summary>
		/// Path to the ONNX model. Use Initialize to change it. 
		/// </summary>
		private string modelPath;
		private int batchSize;

		private SessionOptions SessionOpt;

		/// <summary>
		/// init function
		/// </summary>
		/// <param name="Path"></param>
		/// <param name="BatchSize"></param>
		/// <returns>Returns the output size of the model</returns>
		public int Initialize(string Path, int BatchSize)
		{
			modelPath = Path;
			batchSize = BatchSize;
			SessionOpt = SessionConfigurator.MakeConfiguredSessionOptions();
			session = LoadModel(modelPath);
			return session.OutputMetadata["output"].Dimensions[1];
		}


		/// <include file='docs/ONNXInference.xml' path='docs/members[@name="ONNXInference"]/Run/*'/>
		public Godot.Collections.Dictionary<string, Godot.Collections.Array<float>> RunInference(Godot.Collections.Array<float> obs, int state_ins)
		{
			//Current model: Any (Godot Rl Agents)
			//Expects a tensor of shape [batch_size, input_size] type float named obs and a tensor of shape [batch_size] type float named state_ins

			//Fill the input tensors
			// create span from inputSize
			var span = new float[obs.Count]; //There's probably a better way to do this
			for (int i = 0; i < obs.Count; i++)
			{
				span[i] = obs[i];
			}

			var inputs = new List<NamedOnnxValue>
			{
			NamedOnnxValue.CreateFromTensor("obs", new DenseTensor<float>(span, new int[] { batchSize, obs.Count }))
			};
			if (session.InputMetadata.ContainsKey("state_ins"))
			{
				inputs.Add(NamedOnnxValue.CreateFromTensor("state_ins", new DenseTensor<float>(new float[] { state_ins }, new int[] { batchSize })));
			}
			
			var outputNames = session.OutputMetadata.Keys.ToList();

			try
			{
				using var results = session.Run(inputs, outputNames);
				var outputDict = new Godot.Collections.Dictionary<string, Godot.Collections.Array<float>>();

				foreach (var result in results)
				{
					var valArray = new Godot.Collections.Array<float>();
					foreach (float f in result.AsEnumerable<float>()) { valArray.Add(f); }
					outputDict.Add(result.Name, valArray);
				}
				return outputDict;
			}
			catch (OnnxRuntimeException e)
			{
				GD.Print("Error at inference: ", e);
				return null;
			}
		}
		/// <include file='docs/ONNXInference.xml' path='docs/members[@name="ONNXInference"]/Load/*'/>
		public InferenceSession LoadModel(string Path)
		{
			using Godot.FileAccess file = FileAccess.Open(Path, Godot.FileAccess.ModeFlags.Read);
			byte[] model = file.GetBuffer((int)file.GetLength());
			//file.Close(); file.Dispose(); //Close the file, then dispose the reference.
			return new InferenceSession(model, SessionOpt); //Load the model
		}
		public void FreeDisposables()
		{
			session.Dispose();
			SessionOpt.Dispose();
		}
	}
}
