using Godot;
using System.Collections.Generic;

public partial class Flock : Node2D
{
	[Export] public PackedScene BoidScene { get; set; }
	[Export] public int BoidCount { get; set; } = 60;
	[Export] public float MaxSpeed { get; set; } = 220f;
	[Export] public float MaxForce { get; set; } = 500f;

	[Export] public float SeparationRadius { get; set; } = 28f;
	[Export] public float NeighborRadius { get; set; } = 80f;

	[Export] public float SeparationWeight { get; set; } = 3.0f;
	[Export] public float AlignmentWeight { get; set; } = 2.0f;
	[Export] public float CohesionWeight { get; set; } = 0.5f;
	[Export] public float FollowWeight { get; set; } = 2.0f;

	[ExportGroup("Follow & Gather")]
	[Export] public Node2D Target { get; set; }
	[Export] public float GatherRadius { get; set; } = 85f;
	[Export] public float SlowingDistance { get; set; } = 160f;

	public bool UseSeparation = true;
	public bool UseAlignment = true;
	public bool UseCohesion = true;
	public bool UseFollow = true;

	private List<Boid> boids = new List<Boid>();
	private Vector2[] _steering;

	public override void _Ready()
	{
		ZIndex = -1; // Flock draws behind the player
		if (BoidScene != null)
		{
			SpawnBoids();
		}
		else
		{
			GD.PrintErr("BoidScene is not assigned in the Inspector!");
		}
	}

	private void SpawnBoids()
	{
		Vector2 screen = GetViewportRect().Size;
		_steering = new Vector2[BoidCount];

		for (int i = 0; i < BoidCount; i++)
		{
			float angle = GD.Randf() * Mathf.Tau;
			
			var boid = BoidScene.Instantiate<Boid>();
			boid.Position = new Vector2(GD.Randf(), GD.Randf()) * screen;
			boid.Velocity = Vector2.FromAngle(angle) * MaxSpeed;
			
			AddChild(boid);
			boids.Add(boid);
		}
	}

	private Vector2 SteerTowards(Boid boid, Vector2 direction)
	{
		if (direction.IsZeroApprox()) return Vector2.Zero;
		Vector2 desired = direction.Normalized() * MaxSpeed;
		return (desired - boid.Velocity).LimitLength(MaxForce);
	}

	private Vector2 Separation(Boid boid)
	{
		Vector2 push = Vector2.Zero;
		foreach (Boid other in boids)
		{
			if (other == boid) continue;
			Vector2 away = boid.Position - other.Position;
			float d2 = away.LengthSquared();
			if (d2 > 0f && d2 < SeparationRadius * SeparationRadius)
			{
				push += away / d2;
			}
		}
		return SteerTowards(boid, push);
	}

	private Vector2 Alignment(Boid boid)
	{
		Vector2 headingSum = Vector2.Zero;
		foreach (Boid other in boids)
		{
			if (other == boid) continue;
			float d2 = boid.Position.DistanceSquaredTo(other.Position);
			if (d2 < NeighborRadius * NeighborRadius)
			{
				headingSum += other.Velocity;
			}
		}
		return SteerTowards(boid, headingSum);
	}

	private Vector2 Cohesion(Boid boid)
	{
		Vector2 center = Vector2.Zero;
		int count = 0;
		foreach (Boid other in boids)
		{
			if (other == boid) continue;
			float d2 = boid.Position.DistanceSquaredTo(other.Position);
			if (d2 < NeighborRadius * NeighborRadius)
			{
				center += other.Position;
				count++;
			}
		}
		if (count == 0) return Vector2.Zero;
		center /= count;
		return SteerTowards(boid, center - boid.Position);
	}

	private Vector2 Follow(Boid boid, Vector2 target)
	{
		Vector2 toTarget = target - boid.Position;
		float distance = toTarget.Length();
		if (distance < 0.01f) return Vector2.Zero;

		float gap = distance - GatherRadius;
		float ramp = gap > 0f ? SlowingDistance : GatherRadius * 0.5f;
		float speed = MaxSpeed * Mathf.Clamp(gap / ramp, -1f, 1f);
		Vector2 desired = toTarget / distance * speed;

		return (desired - boid.Velocity).LimitLength(MaxForce);
	}

	public override void _Process(double delta)
	{
		float dt = (float)delta;
		Vector2 screen = GetViewportRect().Size;
		bool following = UseFollow && IsInstanceValid(Target);
		Vector2 target = following ? ToLocal(Target.GlobalPosition) : Vector2.Zero;

		// 1) Decide: calculate steering for everyone first
		for (int i = 0; i < boids.Count; i++)
		{
			Boid boid = boids[i];
			
			Vector2 sep = UseSeparation ? Separation(boid) * SeparationWeight : Vector2.Zero;
			Vector2 ali = UseAlignment ? Alignment(boid) * AlignmentWeight : Vector2.Zero;
			Vector2 coh = UseCohesion ? Cohesion(boid) * CohesionWeight : Vector2.Zero;
			Vector2 fol = Vector2.Zero;

			if (following)
			{
				float d = boid.Position.DistanceTo(target);
				float fade = Mathf.Clamp((d - GatherRadius) / SlowingDistance, 0f, 1f);
				ali *= fade;
				coh *= fade;
				fol = Follow(boid, target) * FollowWeight;
			}

			_steering[i] = (sep + ali + coh + fol).LimitLength(MaxForce);
		}

		// 2) Act: move everyone based on their calculated steering
		for (int i = 0; i < boids.Count; i++)
		{
			Boid boid = boids[i];
			boid.Integrate(_steering[i], MaxSpeed, dt);
			
			if (!following) 
			{
				boid.Position = Wrap(boid.Position, screen);
			}
		}
	}

	private static Vector2 Wrap(Vector2 p, Vector2 size) =>
		new Vector2(Mathf.PosMod(p.X, size.X), Mathf.PosMod(p.Y, size.Y));
}
