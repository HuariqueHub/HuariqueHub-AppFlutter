import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWarmWhite,
      appBar: AppBar(
        title: const Text('Términos y condiciones'),
        backgroundColor: kBrownDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kDividerWarm),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Términos y Condiciones de PuntoSabor',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kBrownDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Última actualización: julio de 2026',
                      style: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                    SizedBox(height: 20),

                    _SectionTitle('1. Aceptación de los términos'),
                    _SectionText(
                      'Al crear una cuenta o iniciar sesión en PuntoSabor, aceptas cumplir estos términos y condiciones. Si no estás de acuerdo, no debes utilizar la aplicación.',
                    ),

                    _SectionTitle('2. Uso de la aplicación'),
                    _SectionText(
                      'PuntoSabor permite descubrir huariques, consultar información, guardar preferencias, revisar promociones y acceder a funcionalidades relacionadas con restaurantes locales. El usuario se compromete a utilizar la aplicación de forma responsable.',
                    ),

                    _SectionTitle('3. Registro de cuenta'),
                    _SectionText(
                      'Para usar ciertas funciones, el usuario debe registrar datos como nombre, correo electrónico y contraseña. El usuario es responsable de mantener la confidencialidad de sus credenciales.',
                    ),

                    _SectionTitle('4. Información del usuario'),
                    _SectionText(
                      'La información ingresada será usada para gestionar la cuenta, personalizar la experiencia dentro de la aplicación y mejorar el servicio ofrecido.',
                    ),

                    _SectionTitle('5. Contenido y reseñas'),
                    _SectionText(
                      'Los usuarios pueden publicar opiniones o reseñas. No se permite contenido ofensivo, falso, discriminatorio, ilegal o que afecte la experiencia de otros usuarios.',
                    ),

                    _SectionTitle('6. Responsabilidad del servicio'),
                    _SectionText(
                      'PuntoSabor busca mostrar información actualizada sobre los huariques, pero no garantiza que todos los datos, horarios, precios o promociones estén siempre disponibles o libres de errores.',
                    ),

                    _SectionTitle('7. Suspensión de cuenta'),
                    _SectionText(
                      'La aplicación puede restringir o suspender cuentas que incumplan estos términos, hagan uso indebido del servicio o generen perjuicio a otros usuarios o establecimientos.',
                    ),

                    _SectionTitle('8. Cambios en los términos'),
                    _SectionText(
                      'PuntoSabor puede actualizar estos términos cuando sea necesario. El uso continuo de la aplicación después de una actualización implica la aceptación de los nuevos términos.',
                    ),

                    _SectionTitle('9. Contacto'),
                    _SectionText(
                      'Si tienes dudas sobre estos términos y condiciones, puedes comunicarte con el equipo de PuntoSabor mediante los canales oficiales de soporte.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: kBrownDark,
        ),
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String text;

  const _SectionText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.45,
        color: kTextPrimary,
      ),
    );
  }
}