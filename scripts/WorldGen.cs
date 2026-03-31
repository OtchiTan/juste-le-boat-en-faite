using System;
using Godot;
using Godot.Collections;

namespace Justeleboatenfaite.scripts;

[GlobalClass]
public partial class WorldGen : TileMapLayer
{
	[Export] public int IslandNumber = 7;
	[Export] public float IslandSize = 30.0f;
	[Export] public Vector2I MapSize = new(700, 400);
	[Export] public PackedScene IslandScene;
	[Export] public PackedScene BoatScene;
	[Export] public float BoatOffset = 900.0f;

	private FastNoiseLite _terrainNoise = new();
	private FastNoiseLite _seaNoise = new();
	private RandomNumberGenerator _rng = new();
	private GodotThread _thread;

	private Array<Vector2I> _islandLocations = new();
	private Dictionary<int, Array<Vector2I>> _terrains = new();
	private Dictionary<Vector2I, int> _tileTerrainMap = new();


	private Dictionary<int, Array<Vector2I>> _islandTiles = new();
	private Dictionary<int, Color> _initialIslandColors = new();

	public override void _Ready()
	{
		_terrainNoise.Seed = 3630;
		_terrainNoise.NoiseType = FastNoiseLite.NoiseTypeEnum.Simplex;

		_seaNoise.Seed = 67;
		_seaNoise.NoiseType = FastNoiseLite.NoiseTypeEnum.Simplex;

		SpawnIslands();

		_thread = new GodotThread();

		_thread.Start(Callable.From(GenerateMap));
	}

	private void GenerateMap()
	{
		for (var x = 0; x < MapSize.X; x++)
		{
			for (var y = 0; y < MapSize.Y; y++)
			{
				var index = new Vector2I(x, y);
				var terrain = GetTileValue(index);

				if (!_terrains.ContainsKey(terrain))
					_terrains[terrain] = new Array<Vector2I>();

				_terrains[terrain].Add(index);


				if (terrain <= 1)
				{
					_tileTerrainMap[index] = 0;
					var islandId = GetNearestIslandId(index);

					if (!_islandTiles.ContainsKey(islandId))
						_islandTiles[islandId] = new Array<Vector2I>();

					_islandTiles[islandId].Add(index);
				}
				else
				{
					_tileTerrainMap[index] = 1;
				}
			}
		}

		CallDeferred(MethodName.RenderTerrain);
	}

	private void RenderTerrain()
	{
		foreach (var entry in _terrains)
		{
			SetCellsTerrainConnect(entry.Value, 0, entry.Key);
		}

		SpawnIslandObjects();

		var uis = GetTree().GetNodesInGroup("minimap_ui");
		if (uis.Count > 0)
		{
			var tileSize = TileSet.TileSize;
			var realWorldSize = MapSize * (Vector2)tileSize;


			uis[0].Call("setup_map_data", MapSize, _tileTerrainMap, _islandTiles, realWorldSize, _initialIslandColors);
		}
	}

	private void SpawnIslands()
	{
		var gridSize = Mathf.CeilToInt(Math.Sqrt(IslandNumber));
		var cellWidth = (float)MapSize.X / gridSize;
		var cellHeight = (float)MapSize.Y / gridSize;

		for (var i = 0; i < gridSize; i++)
		{
			for (var j = 0; j < gridSize; j++)
			{
				var baseX = i * cellWidth + (cellWidth / 2.0f);
				var baseY = j * cellHeight + (cellHeight / 2.0f);

				var offsetX = _rng.RandfRange(-cellWidth * 0.3f, cellWidth * 0.3f);
				var offsetY = _rng.RandfRange(-cellHeight * 0.3f, cellHeight * 0.3f);

				_islandLocations.Add(new Vector2I((int)(baseX + offsetX), (int)(baseY + offsetY)));
			}
		}

		var islandSurplus = _islandLocations.Count - IslandNumber;
		for (var i = 0; i < islandSurplus; i++)
		{
			_islandLocations.RemoveAt(_rng.RandiRange(0, _islandLocations.Count - 1));
		}
	}

	private void SpawnIslandObjects()
	{
		for (var i = 0; i < _islandLocations.Count; i++)
		{
			var islandInstance = IslandScene.Instantiate<Node2D>();


			islandInstance.Set("island_id", i);
			islandInstance.Call("change_owner", i, true);


			var owner = (int)islandInstance.Get("island_owner");
			_initialIslandColors[i] = (owner == 0) ? Colors.DarkGreen : Colors.DarkRed;

			var worldPos = MapToLocal(_islandLocations[i]);
			islandInstance.Position = worldPos;
			AddChild(islandInstance);

			islandInstance.Call("setup", this, _tileTerrainMap);
			SpawnBoatAroundIsland(worldPos, i);
		}
	}

	private void SpawnBoatAroundIsland(Vector2 islandPos, int id)
	{
		var boatInstance = BoatScene.Instantiate<Node2D>();
		var attempt = 0;
		var randomDirection = Vector2.Right.Rotated(_rng.RandfRange(0, Mathf.Tau));
		var tilePos = LocalToMap(islandPos + (randomDirection * BoatOffset));

		while (GetTileValue(tilePos) < 2 && attempt < 10)
		{
			attempt++;
			randomDirection = Vector2.Right.Rotated(_rng.RandfRange(0, Mathf.Tau));
			tilePos = LocalToMap(islandPos + (randomDirection * BoatOffset));
		}

		if (attempt >= 10)
		{
			var waterTiles = _terrains.ContainsKey(2) ? _terrains[2] : new Array<Vector2I>();
			if (waterTiles.Count > 0)
			{
				var randWater = _rng.RandiRange(0, waterTiles.Count - 1);
				boatInstance.Position = MapToLocal(waterTiles[randWater]);
			}
		}
		else
		{
			boatInstance.Position = islandPos + (randomDirection * BoatOffset);
		}

		boatInstance.Call("set_as_player_and_id", id);
		AddChild(boatInstance);
	}

	private int GetTileValue(Vector2I index)
	{
		var nearestIslandDist = GetDistanceToNearestIsland(index);
		var islandDistance = nearestIslandDist / (float)Math.Pow(IslandSize, 2);

		islandDistance += _terrainNoise.GetNoise2D(index.X, index.Y);
		var result = Mathf.Clamp((int)islandDistance, 0, 4);

		if (result > 2)
		{
			result = 2 + (int)(_seaNoise.GetNoise2D(index.X, index.Y) + 1.0f);
		}

		return result;
	}

	private float GetDistanceToNearestIsland(Vector2I index)
	{
		var nearestDistance = float.MaxValue;
		foreach (var island in _islandLocations)
		{
			float distSquared = island.DistanceSquaredTo(index);
			if (distSquared < nearestDistance)
				nearestDistance = distSquared;
		}

		return nearestDistance;
	}

	private int GetNearestIslandId(Vector2I index)
	{
		var nearestDistance = float.MaxValue;
		var nearestId = -1;
		for (var i = 0; i < _islandLocations.Count; i++)
		{
			float dist = _islandLocations[i].DistanceSquaredTo(index);
			if (dist < nearestDistance)
			{
				nearestDistance = dist;
				nearestId = i;
			}
		}

		return nearestId;
	}

	public override void _ExitTree()
	{
		if (_thread != null && _thread.IsStarted())
		{
			_thread.WaitToFinish();
		}
	}
}