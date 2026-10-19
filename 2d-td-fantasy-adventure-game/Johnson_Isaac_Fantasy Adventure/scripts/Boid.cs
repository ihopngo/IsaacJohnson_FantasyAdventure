using Godot;

public partial class Boid : CharacterBody2D
{
	public Vector2 Velocity;
	public Color BodyColor = Colors.White;
	
	// Use AnimatedSprite2D instead of Sprite2D
	private AnimatedSprite2D _animatedSprite;

	public override void _Ready()
	{
		// Grab the AnimatedSprite2D node
		_animatedSprite = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
		_animatedSprite.Play(); // Ensure the animation is running
	}

	public void Integrate(Vector2 accel, float maxSpeed, float dt)
	{
		Velocity = (Velocity + accel * dt).LimitLength(maxSpeed);
		Position += Velocity * dt;

		// Change animation based on direction
		if (Velocity.LengthSquared() > 10f) 
		{
			// Is it moving more horizontally or vertically?
			if (Mathf.Abs(Velocity.X) > Mathf.Abs(Velocity.Y))
			{
				// Horizontal
				if (Velocity.X < 0)
					_animatedSprite.Animation = "left";
				else
					_animatedSprite.Animation = "right";
			}
			else
			{
				// Vertical
				if (Velocity.Y < 0)
					_animatedSprite.Animation = "up";
				else
					_animatedSprite.Animation = "down";
			}
		}
	}
}
