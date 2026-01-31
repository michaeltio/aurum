"use client";

import { useEffect, useRef } from "react";
import * as THREE from "three";
import { AsciiEffect } from "three/examples/jsm/effects/AsciiEffect.js";

export default function AsciiBackground() {
  const mountRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!mountRef.current) return;

    const scene = new THREE.Scene();
    scene.background = new THREE.Color("#020617");

    const camera = new THREE.OrthographicCamera();
    camera.position.z = 10;

    const renderer = new THREE.WebGLRenderer();
    renderer.setSize(window.innerWidth, window.innerHeight);

    const effect = new AsciiEffect(renderer, " .:-=+*#%@", {
      invert: true,
    });

    effect.domElement.style.color = "#303030ff";
    effect.domElement.style.backgroundColor = "#0a0a0aff";
    effect.domElement.style.position = "fixed";
    effect.domElement.style.inset = "0";
    effect.domElement.style.pointerEvents = "none";
    effect.domElement.style.zIndex = "-1";

    mountRef.current.appendChild(effect.domElement);

    let geometry: THREE.PlaneGeometry;
    const material = new THREE.MeshBasicMaterial({
      color: 0xffffff,
      wireframe: true,
    });

    const plane = new THREE.Mesh(undefined as any, material);
    plane.rotation.x = Math.PI / 6;
    scene.add(plane);

    const setup = () => {
      const width = window.innerWidth;
      const height = window.innerHeight;
      const aspect = width / height;

      const viewSize = 10;
      camera.left = (-aspect * viewSize) / 2;
      camera.right = (aspect * viewSize) / 2;
      camera.top = viewSize / 2;
      camera.bottom = -viewSize / 2;
      camera.near = 0.1;
      camera.far = 50;
      camera.updateProjectionMatrix();

      geometry?.dispose();
      geometry = new THREE.PlaneGeometry(
        aspect * viewSize,
        viewSize,
        Math.floor(width / 6),
        Math.floor(height / 20)
      );

      plane.geometry = geometry;

      renderer.setSize(width, height);
      effect.setSize(width, height);
    };

    setup();
    window.addEventListener("resize", setup);

    let time = 0;
    let frameId: number;

    const animate = () => {
      time += 0.04;

      const pos = geometry.attributes.position as THREE.BufferAttribute;

      for (let i = 0; i < pos.count; i++) {
        const x = pos.getX(i);
        const d = Math.abs(x);

        const z = Math.sin(d * 2.5 - time * 2) * Math.exp(-d * 0.25) * 1.6;

        pos.setZ(i, z);
      }

      pos.needsUpdate = true;
      geometry.computeVertexNormals();

      effect.render(scene, camera);
      frameId = requestAnimationFrame(animate);
    };

    animate();

    return () => {
      cancelAnimationFrame(frameId);
      window.removeEventListener("resize", setup);

      geometry.dispose();
      material.dispose();
      renderer.dispose();

      mountRef.current?.removeChild(effect.domElement);
    };
  }, []);

  return <div ref={mountRef} aria-hidden />;
}
