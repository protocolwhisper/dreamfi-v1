import { AppShowcase } from "@/components/app-showcase";
import { Features } from "@/components/features";
import Hero from "@/components/hero";
import Bento from "@/components/landing/bento";
import { UseCases } from '@/components/use-cases';
import { FAQ } from '@/components/faq';
import { CTA } from '@/components/cta';

export default function Home() {
  return (
    <>
      <Hero />
      <Bento />
      <Features />  
      <AppShowcase />
      <UseCases />
      <FAQ />
      <CTA />
    </>
  );
}
