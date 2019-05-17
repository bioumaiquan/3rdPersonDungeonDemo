using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WalkSoundPlayer : MonoBehaviour
{
    AudioSource Sound;
    float time;

    private void Start()
    {
        Sound = GetComponent<AudioSource>();
    }

    void Update()
    {
        time += Time.deltaTime;
    }

    private void OnTriggerEnter(Collider other)
    {
        if (!Sound.isPlaying && time >= 0.4f)
        {
            Sound.Play();
            time = 0;
        }
    }
}
