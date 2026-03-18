using UnityEngine;

/// <summary>
/// Handles cloud layer rotation independently from the planet.
/// Rotates slightly faster than the ocean planet for visual effect.
/// </summary>
public class CloudRotation : MonoBehaviour
{
    [Header("Rotation Settings")]
    [Tooltip("Rotation speed in degrees per second (typically faster than planet)")]
    [Range(-60f, 60f)]
    public float rotationSpeed = 5f;

    [Tooltip("Rotation axis")]
    public Vector3 rotationAxis = Vector3.up;

    [Header("Optional Variation")]
    [Tooltip("Add slight wobble to cloud rotation")]
    public bool enableWobble = false;
    
    [Tooltip("Wobble intensity")]
    [Range(0f, 5f)]
    public float wobbleAmount = 1f;

    private float wobbleTime;

    private void Update()
    {
        float finalSpeed = rotationSpeed;

        // Add slight wobble if enabled
        if (enableWobble)
        {
            wobbleTime += Time.deltaTime;
            finalSpeed += Mathf.Sin(wobbleTime) * wobbleAmount;
        }

        // Rotate clouds
        transform.Rotate(rotationAxis, finalSpeed * Time.deltaTime, Space.Self);
    }
}
