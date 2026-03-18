using UnityEngine;

/// <summary>
/// Handles the slow rotation of the ocean planet on its Y-axis.
/// Optimized for mobile performance.
/// </summary>
public class PlanetRotation : MonoBehaviour
{
    [Header("Rotation Settings")]
    [Tooltip("Rotation speed in degrees per second")]
    [Range(-30f, 30f)]
    public float rotationSpeed = 2f;

    [Tooltip("Rotation axis (default is Y-axis)")]
    public Vector3 rotationAxis = Vector3.up;

    [Header("Performance")]
    [Tooltip("Use unscaled delta time for consistent rotation regardless of game speed")]
    public bool useUnscaledTime = false;

    private void Update()
    {
        float deltaTime = useUnscaledTime ? Time.unscaledDeltaTime : Time.deltaTime;
        
        // Smooth, continuous rotation
        transform.Rotate(rotationAxis, rotationSpeed * deltaTime, Space.Self);
    }
}
