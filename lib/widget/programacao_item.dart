import 'package:flutter/material.dart';

import '../utils/constants.dart';

class ProgramacaoItem extends StatelessWidget {
  final String titulo;
  final String horario;
  final String dias;
  final String apresentador;
  final String imagem;

  const ProgramacaoItem({
    super.key,
    required this.titulo,
    required this.horario,
    required this.dias,
    required this.apresentador,
    required this.imagem
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // fundo azul do card
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$horario ($dias)",
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Locutor(a): $apresentador",
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
          Image.asset("assets/$imagem", width: 60,)
      ],));
  }
}
