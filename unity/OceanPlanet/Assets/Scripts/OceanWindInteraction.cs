using UnityEngine;

/// <summary>
/// Simulates wind effects on the ocean surface based on touch/mouse input.
/// Placeholder structure for future implementation.
/// </summary>
public class OceanWindInteraction : MonoBehaviour
{
    [Header("Wind Settings")]
    [Tooltip("Base wind strength")]
    [Range(0f, 2f)]
    public float windStrength = 0.5f;
    
    [Tooltip("How quickly wind dies down")]
    [Range(0.9f, 0.999f)]
    public float windDecay = 0.98f;

    [Header("Wave Response")]
    [Tooltip("How much waves respond to wind")]
    [Range(0f, 1f)]
    public float waveResponse = 0.3f;

    [Header("Input")]
    [Tooltip("Enable touch input")]
    public bool enableTouchInput = true;
    
    [Tooltip("Enable mouse input (for testing in editor)")]
    public bool enableMouseInput = true;

    private Vector3 currentWind;
    private Material oceanMaterial;
    private Vector2 waveOffset;

    void Start()
    {
        // Get reference to material instance
        Renderer rend = GetComponent<Renderer>();
        if (rend != null)
        {
            oceanMaterial = rend.material;
        }
    }

    void Update()
    {
        HandleInput();
        ApplyWind();
        DecayWind();
    }

    void HandleInput()
    {
        // Mouse input (for testing)
        if (enableMouseInput && Input.GetMouseButton(0))
        {
            Vector3 mousePos = Input.mousePosition;
            ProcessInputAtScreenPosition(mousePos);
        }

        // Touch input
        if (enableTouchInput && Input.touchCount > 0)
        {
            foreach (Touch touch in Input.touches)
            {
                if (touch.phase == TouchPhase.Moved)
                {
                    Vector2 delta = touch.deltaPosition;
                    AddWind(delta * windStrength * 0.1f);
                }
            }
        }
    }

    void ProcessInputAtScreenPosition(Vector3 screenPos)
    {
        Ray ray = Camera.main.ScreenPointToRay(screenPos);
        RaycastHit hit;

        if (Physics.Raycast(ray, out hit))
        {
            if (hit.transform == transform)
            {
                // Calculate wind direction based on swipe
                Vector2 swipeDirection = Input.mousePositionDelta.normalized;
                AddWind(new Vector3(swipeDirection.x, 0, swipeDirection.y) * windStrength);
            }
        }
    }

    void AddWind(Vector3 wind)
    {
        currentWind += wind;
        currentWind = Vector3.ClampMagnitude(currentWind, windStrength * 5f);
    }

    void ApplyWind()
    {
        // Apply wind to wave offset
        if (oceanMaterial != null)
        {
            waveOffset += new Vector2(currentWind.x, currentWind.z) * waveResponse * Time.deltaTime;
            
            // Update shader properties if available
            // oceanMaterial.SetVector("_WindOffset", waveOffset);
        }

        // Apply rotation force to planet (optional)
        // transform.Rotate(Vector3.up, currentWind.x * 0.1f * Time.deltaTime);
    }

    void DecayWind()
    {
        currentWind *= windDecay;
    }

    /// <summary>
    /// Public method to add external wind force (can be called from other scripts)
    /// </summary>
    public void AddExternalWind(Vector3 windForce)
    {
        AddWind(windForce);
    }
}
