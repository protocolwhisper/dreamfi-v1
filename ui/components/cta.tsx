import { Button } from "./ui/button";
import Link from "next/link";

export function CTA() {
  return (
    <section className="py-20">
      <div className="container">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-8">
          <h2 className="text-4xl md:text-5xl font-semibold max-w-2xl text-left max-w-sm">
            Are you ready to join Dream?
          </h2>
          <div className="flex flex-col sm:flex-row gap-4 shrink-0">
            <Button size="lg" className="min-w-[160px]" asChild>
              <Link href="/app">Launch App</Link>
            </Button>
            <Button
              variant="outline"
              size="lg"
              className="min-w-[160px]"
              asChild
            >
              <Link href="/docs">Documentation</Link>
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
} 