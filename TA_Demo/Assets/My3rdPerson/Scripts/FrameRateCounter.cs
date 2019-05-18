using UnityEngine;

public class FrameRateCounter : MonoBehaviour
{
    public float m_update_interval = 0.5f;
    private float m_time_left = 0; // Left time for current interval
    float FPS;

    void Update()
    {
        m_time_left -= Time.deltaTime;
        if (m_time_left <= 0)
        {
            FPS = 1 / Time.deltaTime;
            m_time_left = m_update_interval;
        }
    }

    private void OnGUI()
    {
        GUI.Label(new Rect(20, 20, 100, 30), FPS.ToString());
    }
}
